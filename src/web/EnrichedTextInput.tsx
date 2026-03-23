import { useImperativeHandle } from 'react';
import type {
  EnrichedTextInputInstance,
  EnrichedTextInputProps,
} from '../types';

export const EnrichedTextInput = ({
  ref,
  defaultValue,
}: EnrichedTextInputProps) => {
  useImperativeHandle(
    ref,
    (): EnrichedTextInputInstance => ({
      focus: () => {},
      blur: () => {},
      setValue: () => {},
      setSelection: () => {},
      getHTML: () => Promise.resolve(''),
      toggleBold: () => {},
      toggleItalic: () => {},
      toggleUnderline: () => {},
      toggleStrikeThrough: () => {},
      toggleInlineCode: () => {},
      toggleH1: () => {},
      toggleH2: () => {},
      toggleH3: () => {},
      toggleH4: () => {},
      toggleH5: () => {},
      toggleH6: () => {},
      toggleCodeBlock: () => {},
      toggleBlockQuote: () => {},
      toggleOrderedList: () => {},
      toggleUnorderedList: () => {},
      toggleCheckboxList: () => {},
      setLink: () => {},
      removeLink: () => {},
      setImage: () => {},
      startMention: () => {},
      setMention: () => {},
      measure: () => {},
      measureInWindow: () => {},
      measureLayout: () => {},
      setNativeProps: () => {},
    })
  );

  return <textarea defaultValue={defaultValue} />;
};
