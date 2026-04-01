import { type Editor } from '@tiptap/react';
import type { OnChangeTextEvent } from '../types';
import type { NativeSyntheticEvent } from 'react-native';
import { useOnEditorChange } from './useOnEditorChange';

export const useOnChangeText = (
  editor: Editor,
  onChangeText?: (e: NativeSyntheticEvent<OnChangeTextEvent>) => void
) => {
  useOnEditorChange(editor, onChangeText, (e) =>
    e.getText({ blockSeparator: '\n' })
  );
};
