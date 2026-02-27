import type {
  HostInstance,
  MeasureInWindowOnSuccessCallback,
  MeasureLayoutOnSuccessCallback,
  MeasureOnSuccessCallback,
} from 'react-native';
import { useImperativeHandle } from 'react';
import type { EnrichedTextInputProps } from '../types';

export const EnrichedTextInput = ({ ref }: EnrichedTextInputProps) => {
  useImperativeHandle(ref, () => ({
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
    setImage: () => {},
    startMention: () => {},
    setMention: () => {},
    measure: (_callback: MeasureOnSuccessCallback) => {},
    measureInWindow: (_callback: MeasureInWindowOnSuccessCallback) => {},
    measureLayout: (
      _relativeToNativeComponentRef: HostInstance | number,
      _onSuccess: MeasureLayoutOnSuccessCallback,
      _onFail?: () => void
    ) => {},
    setNativeProps: (_nativeProps: object) => {},
  }));

  console.error(
    'EnrichedTextInput is not supported on web. Please use a regular text input instead.'
  );

  return null;
};
