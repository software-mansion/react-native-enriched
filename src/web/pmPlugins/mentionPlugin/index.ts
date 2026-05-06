import { Extension, getMarkRange } from '@tiptap/core';
import { Slice } from '@tiptap/pm/model';
import { Plugin } from '@tiptap/pm/state';
import type { Editor } from '@tiptap/react';
import { makeMentionPluginState } from './makeMentionPluginState';
import { mentionPluginKey } from './mentionPluginKey';
import { removeMentionMarksIfSpanLengthChanged } from './removeMentionMarksIfSpansResized';
import { stripPartialMentionMarks } from './stripPartialMentionMarks';
import type { MentionPluginOptions, TriggerState } from './types';

export type { MentionPluginOptions, TriggerState } from './types';
export { mentionPluginKey } from './mentionPluginKey';
export { setMention } from './setMention';

export function createMentionPlugin(options: MentionPluginOptions): Extension {
  return Extension.create({
    name: 'mentionTrigger',
    addProseMirrorPlugins() {
      return [
        new Plugin<TriggerState>({
          key: mentionPluginKey,
          props: {
            transformPasted(slice: Slice): Slice {
              return new Slice(
                stripPartialMentionMarks(slice.content),
                slice.openStart,
                slice.openEnd
              );
            },
          },
          state: makeMentionPluginState(options),
          appendTransaction: removeMentionMarksIfSpanLengthChanged,
        }),
      ];
    },
  });
}

// Start a mention trigger by inserting the indicator character.
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

// Hook into editor transaction events to fire mention lifecycle callbacks
// and onMentionDetected. Returns a cleanup function.
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

    const mentionType = state.schema.marks.mention;
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
