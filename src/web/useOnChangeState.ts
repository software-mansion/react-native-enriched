import { useEffect, useRef } from 'react';
import { type Editor } from '@tiptap/react';
import type { OnChangeStateEvent } from '../types';
import type { NativeSyntheticEvent } from 'react-native';
import { adaptWebToNativeEvent } from './adaptWebToNativeEvent';

function makeFormatState(isActive: boolean) {
  return { isActive, isConflicting: false, isBlocking: false };
}

function areFormatStatesEqual(
  a: OnChangeStateEvent['bold'],
  b: OnChangeStateEvent['bold']
): boolean {
  return (
    a.isActive === b.isActive &&
    a.isConflicting === b.isConflicting &&
    a.isBlocking === b.isBlocking
  );
}

function areStatesEqual(a: OnChangeStateEvent, b: OnChangeStateEvent): boolean {
  const keys = Object.keys(a) as Array<keyof OnChangeStateEvent>;

  for (const key of keys) {
    if (!areFormatStatesEqual(a[key], b[key])) {
      return false;
    }
  }

  return true;
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

export const useOnChangeState = (
  editor: Editor | null,
  onChangeState?: (e: NativeSyntheticEvent<OnChangeStateEvent>) => void
) => {
  const lastStateRef = useRef<OnChangeStateEvent | null>(null);

  useEffect(() => {
    if (!editor || !onChangeState) return;

    const handleUpdate = () => {
      const state = buildState(editor);
      if (lastStateRef.current && areStatesEqual(lastStateRef.current, state)) {
        return;
      }
      lastStateRef.current = state;
      onChangeState(adaptWebToNativeEvent(null, state));
    };

    handleUpdate();
    editor.on('transaction', handleUpdate);

    return () => {
      editor.off('transaction', handleUpdate);
    };
  }, [editor, onChangeState]);
};
