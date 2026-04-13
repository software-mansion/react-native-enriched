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

function makeFormatState(isActive: boolean) {
  // TODO: Update this function when adding elements that can be conflicting or
  // blocking. Make sure conflicting and blocking states are in sync between web
  // and native
  return { isActive, isConflicting: false, isBlocking: false };
}

function buildState(editor: Editor): OnChangeStateEvent {
  return {
    bold: makeFormatState(editor.isActive('bold')),
    italic: makeFormatState(editor.isActive('italic')),
    underline: makeFormatState(editor.isActive('underline')),
    strikeThrough: makeFormatState(editor.isActive('strike')),
    inlineCode: makeFormatState(editor.isActive('code')),
    h1: makeFormatState(false),
    h2: makeFormatState(false),
    h3: makeFormatState(false),
    h4: makeFormatState(false),
    h5: makeFormatState(false),
    h6: makeFormatState(false),
    blockQuote: makeFormatState(false),
    codeBlock: makeFormatState(false),
    orderedList: makeFormatState(false),
    unorderedList: makeFormatState(false),
    checkboxList: makeFormatState(false),
    link: makeFormatState(false),
    mention: makeFormatState(false),
    image: makeFormatState(false),
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
