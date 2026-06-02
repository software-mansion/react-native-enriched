import { getMarkRange } from '@tiptap/core';
import type { Editor } from '@tiptap/react';
import type { OnMentionDetected } from '../../../types';
import { mentionPluginKey } from './mentionPluginKey';
import type { MentionCallbacks, TriggerState } from './types';

export function subscribeMentionEvents(
  editor: Editor,
  getCallbacks: () => MentionCallbacks
): () => void {
  let prevTriggerState: TriggerState = { active: false };
  let prevMentionKey: string | null = null;

  const handleTransaction = () => {
    const cb = getCallbacks();
    const curr = mentionPluginKey.getState(editor.state);
    if (!curr) return;

    if (!prevTriggerState.active && curr.active) {
      cb.onStartMention?.(curr.indicator);
      if (curr.query !== '')
        cb.onChangeMention?.({ indicator: curr.indicator, text: curr.query });
    } else if (
      prevTriggerState.active &&
      curr.active &&
      curr.query !== prevTriggerState.query
    ) {
      cb.onChangeMention?.({ indicator: curr.indicator, text: curr.query });
    } else if (prevTriggerState.active && !curr.active) {
      cb.onEndMention?.(prevTriggerState.indicator);
    }
    prevTriggerState = curr;

    const mention = cb.onMentionDetected ? getActiveMention(editor) : null;
    if (!mention) {
      prevMentionKey = null;
      return;
    }
    if (mention.key === prevMentionKey) return;
    prevMentionKey = mention.key;
    cb.onMentionDetected?.({
      text: mention.text,
      indicator: mention.indicator,
      attributes: mention.attributes,
    });
  };

  const handleBlur = () => {
    const cb = getCallbacks();
    if (prevTriggerState.active) {
      cb.onEndMention?.(prevTriggerState.indicator);
      prevTriggerState = { active: false };
    }
    prevMentionKey = null;
  };

  editor.on('transaction', handleTransaction);
  editor.on('blur', handleBlur);

  return () => {
    editor.off('transaction', handleTransaction);
    editor.off('blur', handleBlur);
  };
}

function getActiveMention(
  editor: Editor
): (OnMentionDetected & { key: string }) | null {
  const { state } = editor;
  const mentionType = state.schema.marks.mention;
  if (!mentionType || !state.selection.empty) return null;

  const $pos = state.doc.resolve(state.selection.from);
  const mark = mentionType.isInSet($pos.marks());
  if (!mark) return null;

  const range = getMarkRange($pos, mentionType);
  if (!range) return null;

  const { text, indicator, attributes } = mark.attrs;
  return {
    key: `${range.from}:${range.to}:${text}:${indicator}`,
    text: text as string,
    indicator: indicator as string,
    attributes: (attributes ?? {}) as Record<string, string>,
  };
}
