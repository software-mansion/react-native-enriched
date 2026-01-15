import {
  type Component,
  type RefObject,
  useImperativeHandle,
  useRef,
} from 'react';
import type {
  HostInstance,
  MeasureInWindowOnSuccessCallback,
  MeasureLayoutOnSuccessCallback,
  MeasureOnSuccessCallback,
  NativeMethods,
  TextStyle,
  ViewProps,
} from 'react-native';
import EnrichedTextNativeComponent, {
  type NativeProps,
} from './spec/EnrichedTextNativeComponent';
import { nullthrows } from './utils/nullthrows';

export interface EnrichedTextInstance extends NativeMethods {}

export interface EnrichedTextProps extends Omit<ViewProps, 'children'> {
  ref?: RefObject<EnrichedTextInstance | null>;
  text: string;
  style: TextStyle;
}

type ComponentType = (Component<NativeProps, {}, any> & NativeMethods) | null;

export const EnrichedText = ({
  ref,
  text,
  style,
  ...rest
}: EnrichedTextProps) => {
  const nativeRef = useRef<ComponentType | null>(null);

  useImperativeHandle(ref, () => ({
    measureInWindow: (callback: MeasureInWindowOnSuccessCallback) => {
      nullthrows(nativeRef.current).measureInWindow(callback);
    },
    measure: (callback: MeasureOnSuccessCallback) => {
      nullthrows(nativeRef.current).measure(callback);
    },
    measureLayout: (
      relativeToNativeComponentRef: HostInstance | number,
      onSuccess: MeasureLayoutOnSuccessCallback,
      onFail?: () => void
    ) => {
      nullthrows(nativeRef.current).measureLayout(
        relativeToNativeComponentRef,
        onSuccess,
        onFail
      );
    },
    setNativeProps: (nativeProps: object) => {
      nullthrows(nativeRef.current).setNativeProps(nativeProps);
    },
    focus: () => {
      nullthrows(nativeRef.current).focus();
    },
    blur: () => {
      nullthrows(nativeRef.current).blur();
    },
  }));

  return (
    <EnrichedTextNativeComponent
      ref={nativeRef}
      text={text}
      style={style}
      {...rest}
    />
  );
};
