import { Extension } from '@tiptap/core';
import type { MarkType, Node, Schema } from '@tiptap/pm/model';
import { Plugin, PluginKey, type Transaction } from '@tiptap/pm/state';
import { Mapping } from '@tiptap/pm/transform';
import type { OnLinkDetected } from '../../../types';
import { emitLinkDetected, type LinkEmitterRef } from '../../emitLinkDetected';
import { tiptapPosToNativePos } from '../../positionMapping';
import { findAutolinkRangesInWord } from './autolinkRegex';

interface Run {
  text: string;
  startPos: number;
}

interface DirtyBlock {
  node: Node;
  pos: number;
}

const WHITESPACE_RE = /\S+/g;

function removeAutoLinksInRange(
  doc: Node,
  tr: Transaction,
  linkType: MarkType,
  from: number,
  to: number
): void {
  if (from >= to) return;

  doc.nodesBetween(from, to, (node, pos) => {
    if (!node.isText) return true;

    const link = linkType.isInSet(node.marks);
    if (link?.attrs.auto === true) {
      tr.removeMark(
        Math.max(from, pos),
        Math.min(to, pos + node.nodeSize),
        linkType
      );
    }

    return false;
  });
}

function rangeHasManualLink(
  doc: Node,
  linkType: MarkType,
  from: number,
  to: number
): boolean {
  let found = false;

  doc.nodesBetween(from, to, (node) => {
    if (found) return false;
    if (!node.isText) return true;

    const link = linkType.isInSet(node.marks);
    if (link && link.attrs.auto !== true) found = true;

    return false;
  });

  return found;
}

function extractRuns(
  block: Node,
  blockStartPos: number,
  schema: Schema
): Run[] {
  const runs: Run[] = [];
  let current: Run | null = null;

  block.forEach((child, offset) => {
    const eligibleText =
      child.isText &&
      child.text &&
      !schema.marks.code?.isInSet(child.marks) &&
      !schema.marks.mention?.isInSet(child.marks);

    if (eligibleText) {
      if (!current) {
        current = { text: '', startPos: blockStartPos + 1 + offset };
      }
      current.text += child.text;
      return;
    }

    if (current) {
      runs.push(current);
      current = null;
    }
  });

  if (current) runs.push(current);
  return runs;
}

function scanRunForAutolinks(
  run: Run,
  doc: Node,
  linkType: MarkType,
  linkRegex: RegExp | undefined,
  tr: Transaction,
  detected: OnLinkDetected[]
): void {
  for (const match of run.text.matchAll(WHITESPACE_RE)) {
    const word = match[0];
    const wordStart = run.startPos + match.index!;
    const wordEnd = wordStart + word.length;

    const ranges = findAutolinkRangesInWord(word, linkRegex);
    const fullMatch = ranges.some(
      (r) => r.start === 0 && r.endExclusive === word.length
    );

    if (!fullMatch) continue;
    if (rangeHasManualLink(doc, linkType, wordStart, wordEnd)) continue;

    // const href = prepareUrl(word);
    const href = word;
    tr.addMark(wordStart, wordEnd, linkType.create({ href, auto: true }));
    detected.push({
      text: word,
      url: href,
      start: tiptapPosToNativePos(doc, wordStart),
      end: tiptapPosToNativePos(doc, wordEnd),
    });
  }
}

function getDirtyBlocks(
  doc: Node,
  transactions: readonly Transaction[]
): DirtyBlock[] {
  const mapping = new Mapping();
  for (const tr of transactions) mapping.appendMapping(tr.mapping);

  const blocks = new Map<number, Node>();
  const docSize = doc.content.size;

  mapping.maps.forEach((stepMap, i) => {
    const rest = mapping.slice(i + 1);

    stepMap.forEach((_oldStart, _oldEnd, newStart, newEnd) => {
      const from = Math.max(0, rest.map(newStart, -1) - 1);
      const to = Math.min(docSize, rest.map(newEnd, 1) + 1);

      doc.nodesBetween(from, to, (node, pos) => {
        if (node.type.name === 'codeBlock') return false;

        if (node.inlineContent && !blocks.has(pos)) {
          blocks.set(pos, node);
          return false;
        }

        return true;
      });
    });
  });

  return Array.from(blocks, ([pos, node]) => ({ pos, node }));
}

export function createAutolinkPlugin(ref: LinkEmitterRef): Extension {
  return Extension.create({
    name: 'autolinkDetector',
    addProseMirrorPlugins() {
      return [
        new Plugin({
          key: new PluginKey('autolinkDetector'),
          appendTransaction: (transactions, _oldState, newState) => {
            const state = ref.current;
            if (!state || state.linkRegex === null) return null;

            const { schema, doc, tr } = newState;
            const linkType = schema.marks.link;
            if (!linkType) return null;

            const linkRegex = state.linkRegex ?? undefined;
            const dirtyBlocks = getDirtyBlocks(doc, transactions);
            if (dirtyBlocks.length === 0) return null;

            const detected: OnLinkDetected[] = [];

            for (const { node, pos } of dirtyBlocks) {
              const from = pos + 1;
              const to = pos + node.nodeSize - 1;

              removeAutoLinksInRange(doc, tr, linkType, from, to);

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
            }

            if (tr.steps.length === 0) return null;

            for (const event of detected) emitLinkDetected(ref, event);
            return tr;
          },
        }),
      ];
    },
  });
}
