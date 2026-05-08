import { Extension } from '@tiptap/core';
import { Slice } from '@tiptap/pm/model';
import type { MarkType, Node as PMNode, Schema } from '@tiptap/pm/model';
import type { Transaction } from '@tiptap/pm/state';
import { Plugin, PluginKey } from '@tiptap/pm/state';
import type { OnLinkDetected } from '../../../types';
import { emitLinkDetected, type LinkEmitterRef } from '../../emitLinkDetected';
import { tiptapPosToNativePos } from '../../positionMapping';
import { findAutolinkRangesInWord, prepareUrl } from './autolinkRegex';
import { stripAutolinkMarksOnPaste } from './stripAutolinkMarksOnPaste';

interface Run {
  text: string;
  startPos: number;
}

function rangeHasNonAutoLink(
  doc: PMNode,
  linkType: MarkType,
  from: number,
  to: number
): boolean {
  let found = false;
  doc.nodesBetween(from, to, (node) => {
    if (found) return false;
    if (!node.isText) return true;
    const link = linkType.isInSet(node.marks);
    if (link && link.attrs.auto !== true) {
      found = true;
      return false;
    }
    return false;
  });
  return found;
}

function rangeIsAlreadyAutoLink(
  doc: PMNode,
  linkType: MarkType,
  from: number,
  to: number,
  href: string
): boolean {
  let ok = true;
  doc.nodesBetween(from, to, (node, pos) => {
    if (!ok) return false;
    if (!node.isText) return true;
    const sliceFrom = Math.max(from, pos);
    const sliceTo = Math.min(to, pos + node.nodeSize);
    if (sliceFrom >= sliceTo) return false;
    const link = linkType.isInSet(node.marks);
    if (!link || link.attrs.auto !== true || link.attrs.href !== href) {
      ok = false;
    }
    return false;
  });
  return ok;
}

function removeAutoLinkMarksIn(
  doc: PMNode,
  linkType: MarkType,
  tr: Transaction,
  from: number,
  to: number
): void {
  if (from >= to) return;
  doc.nodesBetween(from, to, (node, pos) => {
    if (!node.isText) return true;
    const link = linkType.isInSet(node.marks);
    if (!link || link.attrs.auto !== true) return false;
    const sliceFrom = Math.max(from, pos);
    const sliceTo = Math.min(to, pos + node.nodeSize);
    if (sliceFrom < sliceTo) {
      tr.removeMark(sliceFrom, sliceTo, linkType);
    }
    return false;
  });
}

/**
 * A "run" is a contiguous span of text inside one inline block that is eligible
 * for autolink detection — i.e. text nodes that are not code-marked and not
 * mention-marked, with no non-text inline nodes between them. URLs are only
 * detected within a single run; runs are separated by code/mention/non-text
 * boundaries (Android parity for word breaks).
 *
 * Runs are concatenated across text-node boundaries so that an existing
 * autolink mark + a freshly typed character (which arrives without the mark)
 * are still recognised as one URL token.
 */
function extractRuns(
  block: PMNode,
  blockStartPos: number,
  schema: Schema
): Run[] {
  const codeMark = schema.marks.code;
  const mentionMark = schema.marks.mention;
  const runs: Run[] = [];
  let cur: Run | null = null;

  block.forEach((child, offsetInBlock) => {
    const innerFrom = blockStartPos + 1 + offsetInBlock;
    if (child.isText && child.text) {
      const ineligible =
        codeMark?.isInSet(child.marks) || mentionMark?.isInSet(child.marks);
      if (ineligible) {
        if (cur) {
          runs.push(cur);
          cur = null;
        }
        return;
      }
      if (!cur) cur = { text: '', startPos: innerFrom };
      cur.text += child.text;
      return;
    }
    if (cur) {
      runs.push(cur);
      cur = null;
    }
  });
  if (cur) runs.push(cur);
  return runs;
}

function scanRunForAutolinks(
  run: Run,
  doc: PMNode,
  linkType: MarkType,
  linkRegex: RegExp | undefined,
  tr: Transaction,
  detected: OnLinkDetected[]
): void {
  const ranges = findAutolinkRangesInWord(run.text, linkRegex);
  const runEnd = run.startPos + run.text.length;
  let cursor = run.startPos;

  for (const r of ranges) {
    const from = run.startPos + r.start;
    const to = run.startPos + r.endExclusive;

    removeAutoLinkMarksIn(doc, linkType, tr, cursor, from);

    if (rangeHasNonAutoLink(doc, linkType, from, to)) {
      cursor = to;
      continue;
    }

    const href = prepareUrl(r.text);
    if (rangeIsAlreadyAutoLink(doc, linkType, from, to, href)) {
      cursor = to;
      continue;
    }

    tr.addMark(from, to, linkType.create({ href, auto: true }));
    detected.push({
      text: r.text,
      url: href,
      start: tiptapPosToNativePos(doc, from),
      end: tiptapPosToNativePos(doc, to),
    });
    cursor = to;
  }
  removeAutoLinkMarksIn(doc, linkType, tr, cursor, runEnd);
}

export function createAutolinkPlugin(ref: LinkEmitterRef): Extension {
  return Extension.create({
    name: 'autolinkDetector',
    addProseMirrorPlugins() {
      return [
        new Plugin({
          key: new PluginKey('autolinkDetector'),
          props: {
            transformPasted: (slice) =>
              new Slice(
                stripAutolinkMarksOnPaste(slice.content),
                slice.openStart,
                slice.openEnd
              ),
          },
          appendTransaction: (transactions, _oldState, newState) => {
            if (!transactions.some((tr) => tr.docChanged)) return null;

            const state = ref.current;
            if (!state) return null;
            if (state.linkRegex === null) return null;
            const linkRegex = state.linkRegex ?? undefined;

            const { schema, doc, tr } = newState;
            const linkType = schema.marks.link;
            if (!linkType) return null;

            const detected: OnLinkDetected[] = [];
            doc.descendants((node, pos) => {
              if (node.type.name === 'codeBlock') return false;
              if (!node.inlineContent) return undefined;
              for (const run of extractRuns(node, pos, schema)) {
                scanRunForAutolinks(
                  run,
                  doc,
                  linkType,
                  linkRegex,
                  tr,
                  detected
                );
              }
              return undefined;
            });

            if (tr.steps.length === 0) return null;

            for (const e of detected) emitLinkDetected(ref, e);
            return tr;
          },
        }),
      ];
    },
  });
}
