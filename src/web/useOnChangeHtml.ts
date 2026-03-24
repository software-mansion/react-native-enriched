import { useEffect, useRef } from 'react';
import { type Editor } from '@tiptap/react';
import type { OnChangeHtmlEvent } from '../types';
import type { NativeSyntheticEvent } from 'react-native';
import { adaptWebToNativeEvent } from './adaptWebToNativeEvent';
import getNormalizedHtml from './getNormalizedHtml';

export const useOnChangeHtml = (
  editor: Editor,
  onChangeHtml?: (e: NativeSyntheticEvent<OnChangeHtmlEvent>) => void
) => {
  const lastHtmlRef = useRef('');

  useEffect(() => {
    if (!onChangeHtml) return;

    const handleUpdate = () => {
      const html = getNormalizedHtml(editor);

      if (html !== lastHtmlRef.current) {
        lastHtmlRef.current = html;
        onChangeHtml(adaptWebToNativeEvent(null, { value: html }));
      }
    };

    handleUpdate();

    editor.on('transaction', handleUpdate);
    editor.on('transaction', () => {});

    return () => {
      editor.off('transaction', handleUpdate);
    };
  }, [editor, onChangeHtml]);
};
