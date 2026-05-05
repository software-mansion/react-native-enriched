import { useEffect, useRef } from 'react';
import { type Editor } from '@tiptap/react';
import type { Transaction } from '@tiptap/pm/state';
import type { OnMentionDetected } from '../types';
import { resolveEnrichedMentionAtPos } from './formats/EnrichedMention';

function sameMentionSnapshot(
  a: {
    text: string;
    indicator: string;
    attributes: Record<string, string>;
    markFrom: number;
    markTo: number;
  },
  b: OnMentionDetected & { markFrom: number; markTo: number }
): boolean {
  if (
    a.text !== b.text ||
    a.indicator !== b.indicator ||
    a.markFrom !== b.markFrom ||
    a.markTo !== b.markTo
  ) {
    return false;
  }
  const keysA = Object.keys(a.attributes).sort();
  const keysB = Object.keys(b.attributes).sort();
  if (keysA.length !== keysB.length) return false;
  for (let i = 0; i < keysA.length; i++) {
    const key = keysA[i];
    if (
      key === undefined ||
      key !== keysB[i] ||
      a.attributes[key] !== b.attributes[key]
    ) {
      return false;
    }
  }
  return true;
}

export const useOnMentionDetected = (
  editor: Editor | null,
  onMentionDetected?: (e: OnMentionDetected) => void
) => {
  const onMentionDetectedRef = useRef(onMentionDetected);
  onMentionDetectedRef.current = onMentionDetected;

  const lastEmittedRef = useRef<
    (OnMentionDetected & { markFrom: number; markTo: number }) | null
  >(null);

  useEffect(() => {
    if (!editor) return;

    const handleUpdate = ({ transaction }: { transaction: Transaction }) => {
      if (!transaction.selectionSet) return;

      const cb = onMentionDetectedRef.current;
      if (!cb) return;

      const { state } = editor;
      if (!state.selection.empty) return;

      const pos = state.selection.from;
      const resolved = resolveEnrichedMentionAtPos(state, pos);

      if (!resolved) {
        lastEmittedRef.current = null;
        return;
      }

      const next = {
        ...resolved.mention,
        markFrom: resolved.from,
        markTo: resolved.to,
      };

      const prev = lastEmittedRef.current;
      if (prev !== null && sameMentionSnapshot(prev, next)) {
        return;
      }

      lastEmittedRef.current = next;
      cb(resolved.mention);
    };

    editor.on('transaction', handleUpdate);

    return () => {
      lastEmittedRef.current = null;
      editor.off('transaction', handleUpdate);
    };
  }, [editor]);
};
