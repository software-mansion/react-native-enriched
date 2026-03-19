import { useEffect, useRef } from 'react';
import { type Editor } from '@tiptap/react';
import type { OnChangeTextEvent } from '../types';
import type { NativeSyntheticEvent } from 'react-native';
import { makeWebEvent } from './makeWebEvent';

export const useOnChangeText = (
  editor: Editor,
  onChangeText?: (e: NativeSyntheticEvent<OnChangeTextEvent>) => void
) => {
  const lastTextRef = useRef('');

  useEffect(() => {
    if (!onChangeText) return;

    const handleUpdate = () => {
      const text = editor.getText({ blockSeparator: '\n' });

      if (text !== lastTextRef.current) {
        lastTextRef.current = text;
        onChangeText(makeWebEvent({ value: text }));
      }
    };

    handleUpdate();

    editor.on('transaction', handleUpdate);

    return () => {
      editor.off('transaction', handleUpdate);
    };
  }, [editor, onChangeText]);
};
