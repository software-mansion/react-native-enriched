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
  let wasInMention = false;

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

    if (!cb.onMentionDetected) return;

    const mention = getActiveMention(editor);
    if (!mention) {
      if (wasInMention) {
        wasInMention = false;
        prevMentionKey = null;
        cb.onMentionDetected({
          text: '',
          indicator: '',
          attributes: {},
        });
      } else {
        prevMentionKey = null;
      }
      return;
    }

    wasInMention = true;
    if (mention.key === prevMentionKey) return;
    prevMentionKey = mention.key;
    cb.onMentionDetected({
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
  if (!mentionType) return null;

  const { from: selFrom, to: selTo } = state.selection;
  const $from = state.doc.resolve(selFrom);
  const mark = mentionType.isInSet($from.marks());
  if (!mark) return null;

  const range = getMarkRange($from, mentionType);
  if (!range) return null;

  if (selFrom < range.from || selTo > range.to) return null;

  const { text, indicator, attributes } = mark.attrs;
  return {
    key: `${range.from}:${range.to}:${text}:${indicator}`,
    text: text as string,
    indicator: indicator as string,
    attributes: (attributes ?? {}) as Record<string, string>,
  };
}
