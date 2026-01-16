import { useEffect, useRef } from 'react';
import { type Editor } from '@tiptap/react';
import type { OnChangeHtmlEvent } from '../../common/types';

export const useEnrichedTextInputHtml = (
  editor: Editor | null,
  onChangeHtml?: (e: OnChangeHtmlEvent) => void
) => {
  const lastHtmlRef = useRef('');

  useEffect(() => {
    if (!editor || !onChangeHtml) return;

    const handleUpdate = () => {
      const html = editor.getHTML();

      // Only call onChangeHtml if HTML has changed
      if (html !== lastHtmlRef.current) {
        console.log('HTML changed:', html);
        lastHtmlRef.current = html;
        onChangeHtml({ value: html });
      }
    };

    // Listen to editor updates
    editor.on('transaction', handleUpdate);

    // Initial update
    handleUpdate();

    return () => {
      editor.off('transaction', handleUpdate);
    };
  }, [editor, onChangeHtml]);
};
