import { type Editor } from '@tiptap/react';
import type { OnChangeTextEvent } from '../types';
import type { NativeSyntheticEvent } from 'react-native';
import { nativeLeafText } from './positionMapping';
import { useOnEditorChange } from './useOnEditorChange';

export const useOnChangeText = (
  editor: Editor,
  onChangeText?: (e: NativeSyntheticEvent<OnChangeTextEvent>) => void
) => {
  useOnEditorChange(editor, onChangeText, (e) => {
    const doc = e.state.doc;
    return nativeLeafText(doc, 0, doc.content.size);
  });
};
