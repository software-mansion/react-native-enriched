import {
  type Component,
  type RefObject,
  useImperativeHandle,
  useRef,
} from 'react';
import ReactNativeRichTextEditorView, {
  Commands,
  type NativeProps,
  type OnChangeStyleEvent,
  type OnChangeTextEvent,
} from './ReactNativeRichTextEditorViewNativeComponent';
import type {
  NativeMethods,
  NativeSyntheticEvent,
  ViewStyle,
} from 'react-native';

export interface RichTextInputInstance {
  // General commands
  focus: () => void;
  blur: () => void;

  // Text formatting commands
  toggleBold: () => void;
  toggleItalic: () => void;
  toggleUnderline: () => void;
  toggleStrikeThrough: () => void;
}

export interface RichTextInputProps {
  ref?: RefObject<RichTextInputInstance | null>;
  defaultValue?: string;
  style?: ViewStyle;
  onChangeText?: (e: NativeSyntheticEvent<OnChangeTextEvent>) => void;
  onChangeStyle?: (e: NativeSyntheticEvent<OnChangeStyleEvent>) => void;
}

const nullthrows = <T,>(value: T | null | undefined): T => {
  if (value == null) {
    throw new Error('Unexpected null or undefined value');
  }

  return value;
};

type ComponentType = (Component<NativeProps, {}, any> & NativeMethods) | null;

export const RichTextInput = ({
  ref,
  defaultValue,
  style,
  onChangeText,
  onChangeStyle,
}: RichTextInputProps) => {
  const nativeRef = useRef<ComponentType | null>(null);

  useImperativeHandle(ref, () => ({
    focus: () => {
      Commands.focus(nullthrows(nativeRef.current));
    },
    blur: () => {
      Commands.blur(nullthrows(nativeRef.current));
    },
    toggleBold: () => {
      Commands.toggleBold(nullthrows(nativeRef.current));
    },
    toggleItalic: () => {
      Commands.toggleItalic(nullthrows(nativeRef.current));
    },
    toggleUnderline: () => {
      Commands.toggleUnderline(nullthrows(nativeRef.current));
    },
    toggleStrikeThrough: () => {
      Commands.toggleStrikeThrough(nullthrows(nativeRef.current));
    },
  }));

  return (
    <ReactNativeRichTextEditorView
      ref={nativeRef}
      defaultValue={defaultValue}
      style={style}
      onChangeText={onChangeText}
      onChangeStyle={onChangeStyle}
    />
  );
};
