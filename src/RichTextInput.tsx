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
  type OnLinkDetectedEvent,
  type OnPressLinkEvent,
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
  toggleInlineCode: () => void;
  toggleH1: () => void;
  toggleH2: () => void;
  toggleH3: () => void;
  setLink: (text: string, url: string) => void;
}

export interface RichTextInputProps {
  ref?: RefObject<RichTextInputInstance | null>;
  defaultValue?: string;
  style?: ViewStyle;
  onChangeText?: (e: NativeSyntheticEvent<OnChangeTextEvent>) => void;
  onChangeStyle?: (e: NativeSyntheticEvent<OnChangeStyleEvent>) => void;
  onPressLink?: (e: NativeSyntheticEvent<OnPressLinkEvent>) => void;
  onLinkDetected?: (e: NativeSyntheticEvent<OnLinkDetectedEvent>) => void;
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
  onPressLink,
  onLinkDetected,
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
    toggleInlineCode: () => {
      Commands.toggleInlineCode(nullthrows(nativeRef.current));
    },
    toggleH1: () => {
      Commands.toggleH1(nullthrows(nativeRef.current));
    },
    toggleH2: () => {
      Commands.toggleH2(nullthrows(nativeRef.current));
    },
    toggleH3: () => {
      Commands.toggleH3(nullthrows(nativeRef.current));
    },
    setLink: (text: string, url: string) => {
      Commands.addLink(nullthrows(nativeRef.current), text, url);
    },
  }));

  return (
    <ReactNativeRichTextEditorView
      ref={nativeRef}
      defaultValue={defaultValue}
      style={style}
      onChangeText={onChangeText}
      onChangeStyle={onChangeStyle}
      onPressLink={onPressLink}
      onLinkDetected={onLinkDetected}
    />
  );
};
