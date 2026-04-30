import { useEffect, useRef } from 'react';
import { type Editor } from '@tiptap/react';
import type { OnChangeStateEvent } from '../types';
import type { NativeSyntheticEvent } from 'react-native';
import { adaptWebToNativeEvent } from './adaptWebToNativeEvent';
import {
  isAnyParagraphFormatActive,
  isFormatBlocked,
} from './formats/formatRules';
import type { HtmlStyle } from '../types';

export const useOnChangeState = (
  editor: Editor | null,
  htmlStyle: Required<HtmlStyle>,
  onChangeState?: (e: NativeSyntheticEvent<OnChangeStateEvent>) => void
) => {
  const lastStateHashRef = useRef<string | null>(null);

  useEffect(() => {
    if (!editor || !onChangeState) return;

    const handleUpdate = () => {
      const state = buildState(editor, htmlStyle);
      const stateHash = hashState(state);

      if (lastStateHashRef.current === stateHash) {
        return;
      }

      lastStateHashRef.current = stateHash;
      onChangeState(adaptWebToNativeEvent(null, state));
    };

    handleUpdate();
    editor.on('transaction', handleUpdate);

    return () => {
      editor.off('transaction', handleUpdate);
    };
  }, [editor, onChangeState, htmlStyle]);
};

function buildState(
  editor: Editor,
  htmlStyle: Required<HtmlStyle>
): OnChangeStateEvent {
  const isAnyBlockActive = isAnyParagraphFormatActive(editor);

  function inlineFormat(tiptapName: string, isConflicting: boolean) {
    return {
      isActive: editor.isActive(tiptapName),
      isConflicting,
      isBlocking: isFormatBlocked(tiptapName, editor, htmlStyle),
    };
  }

  function paragraphFormat(isActive: boolean, additionalIsConflicting = false) {
    return {
      isActive,
      isConflicting: (!isActive && isAnyBlockActive) || additionalIsConflicting,
      isBlocking: false,
    };
  }

  return {
    bold: inlineFormat('bold', false),
    italic: inlineFormat('italic', false),
    underline: inlineFormat('underline', false),
    strikeThrough: inlineFormat('strike', false),
    inlineCode: inlineFormat('code', editor.isActive('link')),
    h1: paragraphFormat(editor.isActive('heading', { level: 1 })),
    h2: paragraphFormat(editor.isActive('heading', { level: 2 })),
    h3: paragraphFormat(editor.isActive('heading', { level: 3 })),
    h4: paragraphFormat(editor.isActive('heading', { level: 4 })),
    h5: paragraphFormat(editor.isActive('heading', { level: 5 })),
    h6: paragraphFormat(editor.isActive('heading', { level: 6 })),
    blockQuote: paragraphFormat(editor.isActive('blockquote')),
    codeBlock: paragraphFormat(
      editor.isActive('codeBlock'),
      editor.isActive('link')
    ),
    orderedList: paragraphFormat(editor.isActive('orderedList')),
    unorderedList: paragraphFormat(editor.isActive('unorderedList')),
    checkboxList: paragraphFormat(editor.isActive('checkboxList')),
    link: inlineFormat(
      'link',
      editor.isActive('code') ||
        editor.isActive('link') ||
        editor.isActive('enrichedCodeBlock')
    ),
    mention: { isActive: false, isConflicting: false, isBlocking: false },
    image: { isActive: false, isConflicting: false, isBlocking: false },
    alignment: 'left',
  };
}

function hashState(state: OnChangeStateEvent): string {
  return Object.values(state)
    .map((formatState) =>
      String(
        getFormatHash(
          formatState.isActive,
          formatState.isConflicting,
          formatState.isBlocking
        )
      )
    )
    .join('');
}

function getFormatHash(
  isActive: boolean,
  isConflicting: boolean,
  isBlocking: boolean
): number {
  // eslint-disable-next-line no-bitwise
  return (+isActive << 2) | (+isConflicting << 1) | (+isBlocking << 0);
}
