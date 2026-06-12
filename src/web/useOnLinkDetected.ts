import { useEffect } from 'react';
import { type Editor } from '@tiptap/react';
import { getMarkRange, getMarksBetween } from '@tiptap/core';
import type { EditorState } from '@tiptap/pm/state';
import type { MarkType } from '@tiptap/pm/model';
import { emitLinkDetected, type LinkEmitterRef } from './emitLinkDetected';
import { tiptapPosToNativePos } from './positionMapping';

function findLinkRangeAt(
  state: EditorState,
  linkType: MarkType
): { from: number; to: number } | null {
  const $pos = state.selection.$from;
  const direct = getMarkRange($pos, linkType);
  if (direct) return direct;
  if ($pos.pos > 0) {
    const $before = state.doc.resolve($pos.pos - 1);
    const before = getMarkRange($before, linkType);
    if (before && before.to === $pos.pos) return before;
  }
  return null;
}

export const useOnLinkDetected = (
  editor: Editor | null,
  ref: LinkEmitterRef
) => {
  useEffect(() => {
    if (!editor) return;

    const handleUpdate = () => {
      const { state } = editor;
      const linkType = state.schema.marks.link;
      if (!linkType) return;

      const range = findLinkRangeAt(state, linkType);

      if (!range) {
        const last = ref.current.lastEmitted;
        if (!last || last.url === '') return;
        emitLinkDetected(ref.current, {
          text: '',
          url: '',
          start: 0,
          end: 0,
        });
        return;
      }

      const linkMark = getMarksBetween(range.from, range.to, state.doc).find(
        (entry) => entry.mark.type === linkType
      )?.mark;
      if (!linkMark) return;

      emitLinkDetected(ref.current, {
        text: state.doc.textBetween(range.from, range.to, '\n'),
        url: (linkMark.attrs.href as string | undefined) ?? '',
        start: tiptapPosToNativePos(state.doc, range.from),
        end: tiptapPosToNativePos(state.doc, range.to),
      });
    };

    handleUpdate();
    editor.on('transaction', handleUpdate);

    return () => {
      editor.off('transaction', handleUpdate);
    };
  }, [editor, ref]);
};
