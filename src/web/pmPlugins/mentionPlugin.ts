import {
  Extension,
  findParentNodeClosestToPos,
  getMarkRange,
} from '@tiptap/core';
import { Fragment, Slice } from '@tiptap/pm/model';
import type {
  Mark as PMark,
  Node as PNode,
  ResolvedPos,
  Schema,
} from '@tiptap/pm/model';
import { Plugin, PluginKey } from '@tiptap/pm/state';
import type { EditorState, StateField, Transaction } from '@tiptap/pm/state';
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

function stripPartialMentionMarks(fragment: Fragment): Fragment {
  const nodes: PNode[] = [];
  fragment.forEach((node) =>
    nodes.push(
      node.isText
        ? node.mark(
            node.marks.filter(
              (m) =>
                m.type.name !== ENRICHED_MENTION_MARK_NAME ||
                node.text === (m.attrs.text as string)
            )
          )
        : node.copy(stripPartialMentionMarks(node.content))
    )
  );
  return Fragment.from(nodes);
}

function isCaretInBlockedContext($from: ResolvedPos, schema: Schema): boolean {
  if (schema.marks[ENRICHED_MENTION_MARK_NAME]?.isInSet($from.marks()))
    return true;
  if (schema.marks.code?.isInSet($from.marks())) return true;
  if (schema.marks.link?.isInSet($from.marks())) return true;
  if (findParentNodeClosestToPos($from, (n) => n.type.name === 'codeBlock'))
    return true;
  return false;
}

export interface MentionPluginOptions {
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

const mentionPluginProps = {
  transformPasted(slice: Slice): Slice {
    return new Slice(
      stripPartialMentionMarks(slice.content),
      slice.openStart,
      slice.openEnd
    );
  },
};

function appendMentionTransaction(
  transactions: readonly Transaction[],
  oldState: EditorState,
  newState: EditorState
): Transaction | null {
  if (!transactions.some((tr) => tr.docChanged)) return null;

  const mentionType = newState.schema.marks[ENRICHED_MENTION_MARK_NAME];
  if (!mentionType) return null;

  type MarkRange = { from: number; to: number; mark: PMark };
  const oldRanges: MarkRange[] = [];

  oldState.doc.descendants((node, pos) => {
    if (!node.isText) return;
    const m = mentionType.isInSet(node.marks);
    if (m) oldRanges.push({ from: pos, to: pos + node.nodeSize, mark: m });
  });

  const merged: MarkRange[] = [];
  for (const range of oldRanges) {
    const prev = merged[merged.length - 1];
    if (prev && prev.mark === range.mark && prev.to === range.from) {
      prev.to = range.to;
    } else {
      merged.push({ ...range });
    }
  }

  const tr = newState.tr;
  let changed = false;

  for (const { from, to, mark } of merged) {
    const origLen = to - from;
    let newFrom = from;
    let newTo = to;

    for (const t of transactions) {
      newFrom = t.mapping.map(newFrom, -1);
      // bias -1 so a split exactly at mention's end keeps newTo in the same paragraph
      newTo = t.mapping.map(newTo, -1);
    }

    if (newTo - newFrom !== origLen) {
      tr.removeMark(newFrom, newTo, mark.type);
      changed = true;
    }
  }

  return changed ? tr : null;
}

function makeMentionPluginState(
  options: MentionPluginOptions
): StateField<TriggerState> {
  return {
    init(): TriggerState {
      return { active: false };
    },

    apply(_tr, _prev, _old, newEditorState): TriggerState {
      const { selection } = newEditorState;
      if (!selection.empty) return { active: false };

      const $from = selection.$from;
      if (isCaretInBlockedContext($from, newEditorState.schema))
        return { active: false };

      const blockStart = $from.start();
      const text = newEditorState.doc.textBetween(
        blockStart,
        $from.pos,
        '\n',
        '\n'
      );

      const indicators = options.indicatorsRef.current;
      const mentionType =
        newEditorState.schema.marks[ENRICHED_MENTION_MARK_NAME];

      let bestIdx = -1;
      let bestIndicator = '';

      for (let idx = text.length - 1; idx >= 0; idx--) {
        const ch = text[idx];
        if (!ch || !indicators.includes(ch)) continue;

        const isAtStart = idx === 0;
        const isAfterSpace = idx > 0 && text[idx - 1] === ' ';
        if (!isAtStart && !isAfterSpace) continue;

        // Skip indicators inside an already-finalized mention to avoid re-activating
        // the trigger immediately after setMention.
        if (mentionType) {
          const $at = newEditorState.doc.resolve(blockStart + idx + 1);
          if (mentionType.isInSet($at.marks())) continue;
        }

        bestIdx = idx;
        bestIndicator = ch;
        break;
      }

      if (bestIdx === -1) return { active: false };

      const query = text.slice(bestIdx + 1);

      // Native platforms end the trigger after two spaces in the query.
      if ((query.match(/ /g) ?? []).length >= 2) return { active: false };

      return {
        active: true,
        indicator: bestIndicator,
        from: blockStart + bestIdx,
        to: $from.pos,
        query,
      };
    },
  };
}

export function createMentionPlugin(options: MentionPluginOptions): Extension {
  return Extension.create({
    name: 'mentionTrigger',
    addProseMirrorPlugins() {
      return [
        new Plugin<TriggerState>({
          key: mentionPluginKey,
          props: mentionPluginProps,
          state: makeMentionPluginState(options),
          appendTransaction: appendMentionTransaction,
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

  const $from = state.selection.$from;
  if (isCaretInBlockedContext($from, state.schema)) {
    console.warn(
      '[EnrichedMention] setMention called but caret is inside a blocked context'
    );
    return;
  }

  const { from, to, indicator } = triggerState;

  // If the user moved the caret back into a partial match, extend `to` over the
  // matching tail to avoid leftover characters after the inserted mention.
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
  const refPos = extendedTo > from ? extendedTo - 1 : from;
  const baseMarks = state.doc
    .resolve(refPos)
    .marks()
    .filter((m) => m.type.name !== ENRICHED_MENTION_MARK_NAME);
  const marksForMention = mentionMark.addToSet(baseMarks);
  const fragment = Fragment.fromArray([
    state.schema.text(text, marksForMention),
    state.schema.text(' ', baseMarks),
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
