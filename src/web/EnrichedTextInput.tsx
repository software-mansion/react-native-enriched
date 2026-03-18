import { useImperativeHandle } from 'react';
import type { ViewStyle, TextStyle } from 'react-native';
import type {
  BaseEnrichedTextInputProps,
  EnrichedTextInputInstance,
} from '../types';

// Web-specific props — extends the shared base. style will diverge from the
// native variant in the future (e.g. CSSProperties vs ViewStyle/TextStyle).
export interface EnrichedTextInputProps extends BaseEnrichedTextInputProps {
  style?: ViewStyle | TextStyle;
}

export const EnrichedTextInput = ({ ref }: EnrichedTextInputProps) => {
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

  return <div />;
};
