import { useEffect, useRef } from 'react';
import { type Editor } from '@tiptap/react';
import type { NativeSyntheticEvent } from 'react-native';
import { adaptWebToNativeEvent } from './adaptWebToNativeEvent';

export const useOnEditorChange = <T extends { value: string }>(
  editor: Editor,
  handler: ((e: NativeSyntheticEvent<T>) => void) | undefined,
  getValue: (editor: Editor) => string
) => {
  const lastValueRef = useRef('');

  useEffect(() => {
    if (!handler) return;

    const handleUpdate = () => {
      const value = getValue(editor);

      if (value !== lastValueRef.current) {
        lastValueRef.current = value;
        handler(adaptWebToNativeEvent(null, { value } as T));
      }
    };

    handleUpdate();

    editor.on('transaction', handleUpdate);

    return () => {
      editor.off('transaction', handleUpdate);
    };
  }, [editor, handler, getValue]);
};
