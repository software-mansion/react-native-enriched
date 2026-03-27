import { type Editor } from '@tiptap/react';
import type { OnChangeHtmlEvent } from '../types';
import type { NativeSyntheticEvent } from 'react-native';
import { useOnEditorChange } from './useOnEditorChange';
import getNormalizedHtml from './getNormalizedHtml';

export const useOnChangeHtml = (
  editor: Editor,
  onChangeHtml?: (e: NativeSyntheticEvent<OnChangeHtmlEvent>) => void
) => {
  useOnEditorChange(editor, onChangeHtml, getNormalizedHtml);
};
