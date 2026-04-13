import { useEffect, useRef } from 'react';
import { type Editor } from '@tiptap/react';
import type { OnChangeStateEvent } from '../types';
import type { NativeSyntheticEvent } from 'react-native';
import { adaptWebToNativeEvent } from './adaptWebToNativeEvent';

export const useOnChangeState = (
  editor: Editor | null,
  onChangeState?: (e: NativeSyntheticEvent<OnChangeStateEvent>) => void
) => {
  const lastStateHashRef = useRef<string | null>(null);

  useEffect(() => {
    if (!editor || !onChangeState) return;

    const handleUpdate = () => {
      const state = buildState(editor);
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
  }, [editor, onChangeState]);
};

function buildState(editor: Editor): OnChangeStateEvent {
  const isCodeBlockActive = editor.isActive('enrichedCodeBlock');
  const isBlockquoteActive = editor.isActive('blockquote');
  const inlineBlocked = isCodeBlockActive;

  function paragraphFormat(isActive: boolean) {
    return {
      isActive,
      isConflicting: false,
      isBlocking: false,
    };
  }

  return {
    bold: {
      isActive: editor.isActive('bold'),
      isConflicting: false,
      isBlocking: inlineBlocked,
    },
    italic: {
      isActive: editor.isActive('italic'),
      isConflicting: false,
      isBlocking: inlineBlocked,
    },
    underline: {
      isActive: editor.isActive('underline'),
      isConflicting: false,
      isBlocking: inlineBlocked,
    },
    strikeThrough: {
      isActive: editor.isActive('strike'),
      isConflicting: false,
      isBlocking: inlineBlocked,
    },
    inlineCode: {
      isActive: editor.isActive('code'),
      isConflicting: false,
      isBlocking: inlineBlocked,
    },
    h1: paragraphFormat(editor.isActive('heading', { level: 1 })),
    h2: paragraphFormat(editor.isActive('heading', { level: 2 })),
    h3: paragraphFormat(editor.isActive('heading', { level: 3 })),
    h4: paragraphFormat(editor.isActive('heading', { level: 4 })),
    h5: paragraphFormat(editor.isActive('heading', { level: 5 })),
    h6: paragraphFormat(editor.isActive('heading', { level: 6 })),
    blockQuote: paragraphFormat(isBlockquoteActive),
    codeBlock: paragraphFormat(isCodeBlockActive),
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
