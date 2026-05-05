import { Extension, getMarkRange } from '@tiptap/core';
import { Fragment } from '@tiptap/pm/model';
import type { Mark as PMark } from '@tiptap/pm/model';
import { Plugin, PluginKey } from '@tiptap/pm/state';
import type { Transaction } from '@tiptap/pm/state';
import type { Editor } from '@tiptap/react';
import type { OnChangeMentionEvent, OnMentionDetected } from '../../types';
import { ENRICHED_MENTION_MARK_NAME } from '../formats/EnrichedMention';

export type TriggerState =
  | { active: false }
  | {
      active: true;
      indicator: string;
      from: number;
      to: number;
      query: string;
    };

export const mentionPluginKey = new PluginKey<TriggerState>('mention');

interface MentionPluginOptions {
  indicatorsRef: { current: string[] };
  callbacksRef: {
    current: {
      onStartMention?: (indicator: string) => void;
      onChangeMention?: (e: OnChangeMentionEvent) => void;
      onEndMention?: (indicator: string) => void;
      onMentionDetected?: (e: OnMentionDetected) => void;
    };
  };
}

export function createMentionPlugin(options: MentionPluginOptions): Extension {
  return Extension.create({
    name: 'mentionTrigger',

    addProseMirrorPlugins() {
      return [
        new Plugin<TriggerState>({
          key: mentionPluginKey,

          state: {
            init(): TriggerState {
              return { active: false };
            },

            apply(
              _tr: Transaction,
              _prevState: TriggerState,
              _oldEditorState,
              newEditorState
            ): TriggerState {
              const { selection } = newEditorState;

              // Non-empty selection → no trigger
              if (!selection.empty) {
                return { active: false };
              }

              const $from = selection.$from;

              // Blocker marks: inside mention, code, or link
              const mentionType =
                newEditorState.schema.marks[ENRICHED_MENTION_MARK_NAME];
              if (mentionType && mentionType.isInSet($from.marks())) {
                return { active: false };
              }

              const codeType = newEditorState.schema.marks.code;
              if (codeType && codeType.isInSet($from.marks())) {
                return { active: false };
              }

              const linkType = newEditorState.schema.marks.link;
              if (linkType && linkType.isInSet($from.marks())) {
                return { active: false };
              }

              // Blocker node: inside code block
              if ($from.parent.type.name === 'codeBlock') {
                return { active: false };
              }

              // Get text from start of block to caret
              const blockStart = $from.start();
              const text = newEditorState.doc.textBetween(
                blockStart,
                $from.pos,
                '\n',
                '\n'
              );

              const indicators = options.indicatorsRef.current;

              // Scan backwards for rightmost valid indicator
              let bestIdx = -1;
              let bestIndicator = '';

              for (let idx = text.length - 1; idx >= 0; idx--) {
                const ch = text[idx];
                if (!ch || !indicators.includes(ch)) continue;
                // Valid position: at start of text OR preceded by a space
                const isAtStart = idx === 0;
                const isAfterSpace = idx > 0 && text[idx - 1] === ' ';
                if (!isAtStart && !isAfterSpace) continue;

                // Skip indicators that are part of an already-finalized mention — otherwise the
                // just-inserted mention's '@' would re-activate the trigger immediately after setMention.
                if (mentionType) {
                  const $at = newEditorState.doc.resolve(blockStart + idx + 1);
                  if (mentionType.isInSet($at.marks())) continue;
                }

                bestIdx = idx;
                bestIndicator = ch;
                break;
              }

              if (bestIdx === -1) {
                return { active: false };
              }

              const query = text.slice(bestIdx + 1);

              // Native platforms end the trigger after two spaces in the query
              // (e.g. "@john doe " → 2 spaces → end; "@john doe" → 1 → still active).
              const spaceCount = (query.match(/ /g) ?? []).length;
              if (spaceCount >= 2) {
                return { active: false };
              }

              const from = blockStart + bestIdx;
              const to = $from.pos;

              return {
                active: true,
                indicator: bestIndicator,
                from,
                to,
                query,
              };
            },
          },

          appendTransaction(transactions, oldState, newState) {
            if (!transactions.some((tr) => tr.docChanged)) {
              return null;
            }

            const mentionType =
              newState.schema.marks[ENRICHED_MENTION_MARK_NAME];
            if (!mentionType) return null;

            // Collect all mention mark ranges in the OLD doc
            type MarkRange = { from: number; to: number; mark: PMark };
            const oldRanges: MarkRange[] = [];

            oldState.doc.descendants((node, pos) => {
              if (!node.isText) return;
              const m = mentionType.isInSet(node.marks);
              if (m) {
                oldRanges.push({
                  from: pos,
                  to: pos + node.nodeSize,
                  mark: m,
                });
              }
            });

            // Merge adjacent ranges with same mark instance
            const merged: MarkRange[] = [];
            for (const range of oldRanges) {
              const prev = merged[merged.length - 1];
              if (prev && prev.mark === range.mark && prev.to === range.from) {
                prev.to = range.to;
              } else {
                merged.push({ ...range });
              }
            }

            // For each old range, map through all transactions and check length
            const tr = newState.tr;
            let changed = false;

            for (const { from, to, mark } of merged) {
              const origLen = to - from;
              let newFrom = from;
              let newTo = to;

              for (const t of transactions) {
                newFrom = t.mapping.map(newFrom, -1);
                // Use bias -1 so a split exactly at the mention's end keeps newTo
                // in the same paragraph instead of jumping into the new one (+2).
                newTo = t.mapping.map(newTo, -1);
              }

              const newLen = newTo - newFrom;
              if (newLen !== origLen) {
                tr.removeMark(newFrom, newTo, mark.type);
                changed = true;
              }
            }

            return changed ? tr : null;
          },
        }),
      ];
    },
  });
}

/**
 * Insert a mention mark at the current active trigger range.
 * `text` should include the indicator (e.g. "@John Doe").
 */
export function setMention(
  editor: Editor,
  text: string,
  attributes?: Record<string, string>
): void {
  const { state } = editor;
  const triggerState = mentionPluginKey.getState(state);

  if (!triggerState?.active) {
    console.warn(
      '[EnrichedMention] setMention called but there is no active mention trigger'
    );
    return;
  }

  const mentionType = state.schema.marks[ENRICHED_MENTION_MARK_NAME];
  if (!mentionType) return;

  // Check blockers
  const $from = state.selection.$from;
  const codeType = state.schema.marks.code;
  if (codeType && codeType.isInSet($from.marks())) {
    console.warn(
      '[EnrichedMention] setMention called but caret is inside code mark'
    );
    return;
  }
  const linkType = state.schema.marks.link;
  if (linkType && linkType.isInSet($from.marks())) {
    console.warn(
      '[EnrichedMention] setMention called but caret is inside link mark'
    );
    return;
  }
  if ($from.parent.type.name === 'codeBlock') {
    console.warn(
      '[EnrichedMention] setMention called but caret is inside codeBlock'
    );
    return;
  }

  const { from, to, indicator } = triggerState;

  // If the user moved the caret back into a partial match (e.g. caret between
  // "@John " and "Doe" with canonical text "@John Doe"), extending `to` over the
  // matching tail prevents leftover characters after the inserted mention.
  const parentEnd = state.doc.resolve(from).end();
  let extendedTo = to;
  let scanPos = from;
  let prefixMatches = true;
  for (const ch of text) {
    const step = ch.length;
    if (
      scanPos + step > parentEnd ||
      state.doc.textBetween(scanPos, scanPos + step, '') !== ch
    ) {
      prefixMatches = false;
      break;
    }
    scanPos += step;
  }
  if (prefixMatches) extendedTo = Math.max(to, scanPos);

  const mentionMark = mentionType.create({
    indicator,
    text,
    attributes: attributes ?? {},
  });

  const fragment = Fragment.fromArray([
    state.schema.text(text, [mentionMark]),
    state.schema.text(' '),
  ]);

  editor
    .chain()
    .focus()
    .command(({ tr }) => {
      tr.replaceWith(from, extendedTo, fragment);
      return true;
    })
    .run();
}

/**
 * Start a mention trigger by inserting the indicator character.
 */
export function startMention(
  editor: Editor,
  indicator: string,
  indicators: string[]
): void {
  if (!indicators.includes(indicator)) {
    console.warn(
      `[EnrichedMention] startMention: "${indicator}" is not in mentionIndicators`
    );
  }
  editor.chain().focus().insertContent(indicator).run();
}

/**
 * Hook into editor transaction events to fire mention lifecycle callbacks
 * and onMentionDetected. Returns a cleanup function.
 */
export function subscribeMentionEvents(
  editor: Editor,
  callbacksRef: MentionPluginOptions['callbacksRef']
): () => void {
  let prevTriggerState: TriggerState = { active: false };
  let prevMentionSnapshot: string | null = null;

  const handleTransaction = () => {
    const cb = callbacksRef.current;
    const curr = mentionPluginKey.getState(editor.state);
    if (!curr) return;

    // Trigger lifecycle
    if (!prevTriggerState.active && curr.active) {
      cb.onStartMention?.(curr.indicator);
      if (curr.query !== '') {
        cb.onChangeMention?.({ indicator: curr.indicator, text: curr.query });
      }
    } else if (prevTriggerState.active && curr.active) {
      if (curr.query !== prevTriggerState.query) {
        cb.onChangeMention?.({ indicator: curr.indicator, text: curr.query });
      }
    } else if (prevTriggerState.active && !curr.active) {
      cb.onEndMention?.(prevTriggerState.indicator);
    }
    prevTriggerState = curr;

    // onMentionDetected
    if (!cb.onMentionDetected) {
      prevMentionSnapshot = null;
      return;
    }

    const { state } = editor;
    if (!state.selection.empty) {
      prevMentionSnapshot = null;
      return;
    }

    const mentionType = state.schema.marks[ENRICHED_MENTION_MARK_NAME];
    if (!mentionType) {
      prevMentionSnapshot = null;
      return;
    }

    const $pos = state.doc.resolve(state.selection.from);
    const mentionMark = mentionType.isInSet($pos.marks());
    if (!mentionMark) {
      prevMentionSnapshot = null;
      return;
    }

    const range = getMarkRange($pos, mentionType);
    if (!range) {
      prevMentionSnapshot = null;
      return;
    }

    const { from, to } = range;
    const snapshot = JSON.stringify({
      from,
      to,
      text: mentionMark.attrs.text,
      indicator: mentionMark.attrs.indicator,
      attributes: mentionMark.attrs.attributes,
    });

    if (snapshot === prevMentionSnapshot) return;
    prevMentionSnapshot = snapshot;

    cb.onMentionDetected?.({
      text: mentionMark.attrs.text as string,
      indicator: mentionMark.attrs.indicator as string,
      attributes: (mentionMark.attrs.attributes ?? {}) as Record<
        string,
        string
      >,
    });
  };

  const handleBlur = () => {
    if (prevTriggerState.active) {
      callbacksRef.current.onEndMention?.(prevTriggerState.indicator);
      prevTriggerState = { active: false };
    }
    prevMentionSnapshot = null;
  };

  editor.on('transaction', handleTransaction);
  editor.on('blur', handleBlur);

  return () => {
    editor.off('transaction', handleTransaction);
    editor.off('blur', handleBlur);
  };
}
