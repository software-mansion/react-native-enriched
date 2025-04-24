import {
  type Component,
  type RefObject,
  useImperativeHandle,
  useRef,
  useState,
} from 'react';
import ReactNativeRichTextEditorView, {
  Commands,
  type NativeProps,
  type OnChangeTextEvent,
} from './ReactNativeRichTextEditorViewNativeComponent';
import type {
  NativeMethods,
  NativeSyntheticEvent,
  ViewStyle,
} from 'react-native';

export interface RichTextInputInstance {
  focus: () => void;
  blur: () => void;
}

export interface RichTextInputProps {
  ref?: RefObject<RichTextInputInstance | null>;
  defaultValue?: string;
  style?: ViewStyle;
  onChangeText?: (e: NativeSyntheticEvent<OnChangeTextEvent>) => void;
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
}: RichTextInputProps) => {
  const [value, setValue] = useState('');
  const nativeRef = useRef<ComponentType | null>(null);

  useImperativeHandle(ref, () => ({
    focus: () => {
      Commands.focus(nullthrows(nativeRef.current));
    },
    blur: () => {
      Commands.blur(nullthrows(nativeRef.current));
    },
  }));

  const onChangeTextInternal = (e: NativeSyntheticEvent<OnChangeTextEvent>) => {
    setValue(e.nativeEvent.value);
    onChangeText?.(e);
  };

  return (
    <ReactNativeRichTextEditorView
      value={value}
      ref={nativeRef}
      defaultValue={defaultValue}
      style={style}
      onChangeText={onChangeTextInternal}
    />
  );
};
