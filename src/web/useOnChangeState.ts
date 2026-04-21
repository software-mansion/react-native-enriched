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

  function inlineFormat(tiptapName: string) {
    return {
      isActive: editor.isActive(tiptapName),
      isConflicting: false,
      isBlocking: isFormatBlocked(tiptapName, editor, htmlStyle),
    };
  }

  function paragraphFormat(isActive: boolean) {
    return {
      isActive,
      isConflicting: !isActive && isAnyBlockActive,
      isBlocking: false,
    };
  }

  return {
    bold: inlineFormat('bold'),
    italic: inlineFormat('italic'),
    underline: inlineFormat('underline'),
    strikeThrough: inlineFormat('strike'),
    inlineCode: inlineFormat('code'),
    h1: paragraphFormat(editor.isActive('heading', { level: 1 })),
    h2: paragraphFormat(editor.isActive('heading', { level: 2 })),
    h3: paragraphFormat(editor.isActive('heading', { level: 3 })),
    h4: paragraphFormat(editor.isActive('heading', { level: 4 })),
    h5: paragraphFormat(editor.isActive('heading', { level: 5 })),
    h6: paragraphFormat(editor.isActive('heading', { level: 6 })),
    blockQuote: paragraphFormat(editor.isActive('blockquote')),
    codeBlock: paragraphFormat(editor.isActive('codeBlock')),
    orderedList: paragraphFormat(false),
    unorderedList: paragraphFormat(false),
    checkboxList: paragraphFormat(false),
    link: { isActive: false, isConflicting: false, isBlocking: false },
    mention: { isActive: false, isConflicting: false, isBlocking: false },
    image: { isActive: false, isConflicting: false, isBlocking: false },
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
