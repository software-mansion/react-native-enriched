import { Extension } from '@tiptap/core';
import type { Node as PMNode } from '@tiptap/pm/model';
import { Plugin, PluginKey, type Transaction } from '@tiptap/pm/state';
import { Mapping } from '@tiptap/pm/transform';
import { nativeLeafText } from '../nativeMappers/positionMapping';

interface MaxLengthPluginOptions {
  getMaxLength: () => number | undefined;
}

const ZERO_WIDTH_SPACE = '\u200B';

function plainLength(text: string): number {
  return text.replaceAll(ZERO_WIDTH_SPACE, '').length;
}

function docPlainLength(doc: PMNode): number {
  return plainLength(nativeLeafText(doc, 0, doc.content.size));
}

/**
 * Ranges newly inserted by `transactions`, expressed in the coordinates of
 * the final document. Used to know what to trim so truncation only eats into
 * the content that was just typed/pasted/inserted, leaving everything else
 * (in particular, anything that followed the caret) untouched.
 */
function getInsertedRanges(
  transactions: readonly Transaction[]
): Array<[number, number]> {
  const ranges: Array<[number, number]> = [];

  transactions.forEach((tr, trIndex) => {
    const maps = tr.mapping.maps;
    const restOfBatch = new Mapping();
    for (let i = trIndex + 1; i < transactions.length; i++) {
      restOfBatch.appendMapping(transactions[i]!.mapping);
    }

    maps.forEach((stepMap, stepIndex) => {
      stepMap.forEach((_oldStart, _oldEnd, newStart, newEnd) => {
        if (newEnd <= newStart) return;
        let from = newStart;
        let to = newEnd;
        for (let i = stepIndex + 1; i < maps.length; i++) {
          from = maps[i]!.map(from, -1);
          to = maps[i]!.map(to, 1);
        }
        from = restOfBatch.map(from, -1);
        to = restOfBatch.map(to, 1);
        if (to > from) ranges.push([from, to]);
      });
    });
  });

  return ranges;
}

/**
 * Finds the position within [from, to) where the plain-text length
 * of [from, cut) is `keep`. Snaps outward inside composed characters,
 * so e.g. emojis, surrogate pairs, and combining marks are never split.
 */
function findCutPosition(
  doc: PMNode,
  from: number,
  to: number,
  keep: number
): number {
  if (keep <= 0) return from;

  const segmenter =
    typeof Intl !== 'undefined' && 'Segmenter' in Intl
      ? new Intl.Segmenter(undefined, { granularity: 'grapheme' })
      : null;

  let units = 0;
  let cut = to;
  let done = false;
  let visitedBlock = false;

  doc.nodesBetween(from, to, (node, pos) => {
    if (done) return false;

    if (node.isBlock) {
      if (visitedBlock) {
        // Implicit '\n' separator `nativeLeafText` inserts between blocks.
        if (units >= keep) {
          cut = pos;
          done = true;
          return false;
        }
        units += 1;
      }
      visitedBlock = true;
      return true;
    }

    if (!node.isLeaf) return true;

    const nodeFrom = Math.max(from, pos);
    const nodeTo = Math.min(to, pos + node.nodeSize);

    if (!node.isText) {
      // Atomic leaf (e.g. image): one unit, cannot be partially kept.
      if (units >= keep) {
        cut = pos;
        done = true;
        return false;
      }
      units += 1;
      return false;
    }

    const text = node.text ?? '';
    const slice = text.slice(nodeFrom - pos, nodeTo - pos);
    const segments = segmenter
      ? Array.from(segmenter.segment(slice), (s) => s.segment)
      : Array.from(slice);

    let offset = 0;
    for (const segment of segments) {
      const segmentUnits = segment === ZERO_WIDTH_SPACE ? 0 : segment.length;
      if (units + segmentUnits > keep) {
        cut = nodeFrom + offset;
        done = true;
        return false;
      }
      units += segmentUnits;
      offset += segment.length;
    }

    return false;
  });

  return cut;
}

export const MaxLengthPlugin = Extension.create<MaxLengthPluginOptions>({
  name: 'maxLength',

  addOptions() {
    return { getMaxLength: () => undefined };
  },

  addProseMirrorPlugins() {
    return [
      new Plugin({
        key: new PluginKey('maxLength'),
        appendTransaction: (transactions, _oldState, newState) => {
          const maxLength = this.options.getMaxLength();
          if (maxLength == null || maxLength < 0) return null;
          if (!transactions.some((tr) => tr.docChanged)) return null;

          let overflow = docPlainLength(newState.doc) - maxLength;
          if (overflow <= 0) return null;

          const insertedRanges = getInsertedRanges(transactions);
          const tr = newState.tr;

          for (let i = insertedRanges.length - 1; i >= 0 && overflow > 0; i--) {
            const [rangeFrom, rangeTo] = insertedRanges[i]!;
            const from = tr.mapping.map(rangeFrom, -1);
            const to = tr.mapping.map(rangeTo, 1);
            if (to <= from) continue;

            const rangeLength = plainLength(nativeLeafText(tr.doc, from, to));
            const removable = Math.min(overflow, rangeLength);
            if (removable <= 0) continue;

            const cut = findCutPosition(
              tr.doc,
              from,
              to,
              rangeLength - removable
            );
            if (cut >= to) continue;

            tr.delete(cut, to);
            overflow -= removable;
          }

          if (!tr.docChanged) return null;
          tr.setMeta('addToHistory', false);
          return tr;
        },
      }),
    ];
  },
});
