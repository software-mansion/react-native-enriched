import { useEffect, useRef } from 'react';
import { type Editor } from '@tiptap/react';
import type { OnChangeHtmlEvent } from '../../common/types';

export const useOnChangeHtml = (
  editor: Editor | null,
  onChangeHtml?: (e: OnChangeHtmlEvent) => void
) => {
  const lastHtmlRef = useRef('');

  useEffect(() => {
    if (!editor || !onChangeHtml) return;

    const handleUpdate = () => {
      const html = editor.getHTML();

      if (html !== lastHtmlRef.current) {
        lastHtmlRef.current = html;
        onChangeHtml({ value: html });
      }
    };

    // Initial update
    handleUpdate();

    editor.on('transaction', handleUpdate);

    return () => {
      editor.off('transaction', handleUpdate);
    };
  }, [editor, onChangeHtml]);
};
