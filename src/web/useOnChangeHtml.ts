import { useEffect, useRef } from 'react';
import { type Editor } from '@tiptap/react';
import type { OnChangeHtmlEvent } from '../types';
import type { NativeSyntheticEvent } from 'react-native';
import { makeWebEvent } from './makeWebEvent';
import getNormalizedHtml from './getNormalizedHtml';

export const useOnChangeHtml = (
  editor: Editor | null,
  onChangeHtml?: (e: NativeSyntheticEvent<OnChangeHtmlEvent>) => void
) => {
  const lastHtmlRef = useRef('');

  useEffect(() => {
    if (!editor || !onChangeHtml) return;

    const handleUpdate = () => {
      const html = getNormalizedHtml(editor);

      if (html !== lastHtmlRef.current) {
        lastHtmlRef.current = html;
        onChangeHtml(makeWebEvent({ value: html }));
      }
    };

    handleUpdate();

    editor.on('transaction', handleUpdate);

    return () => {
      editor.off('transaction', handleUpdate);
    };
  }, [editor, onChangeHtml]);
};
