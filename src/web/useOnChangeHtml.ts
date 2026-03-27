import { type Editor } from '@tiptap/react';
import type { OnChangeHtmlEvent } from '../types';
import type { NativeSyntheticEvent } from 'react-native';
import { useOnEditorChange } from './useOnEditorChange';
import { normalizeHtmlFromTiptap } from './tiptapHtmlNormalizer';

export const useOnChangeHtml = (
  editor: Editor,
  onChangeHtml?: (e: NativeSyntheticEvent<OnChangeHtmlEvent>) => void
) => {
  useOnEditorChange(editor, onChangeHtml, (e) =>
    normalizeHtmlFromTiptap(e.getHTML())
  );
};
