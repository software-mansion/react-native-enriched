import {
  type Component,
  type RefObject,
  useImperativeHandle,
  useMemo,
  useRef,
} from 'react';
import type {
  ColorValue,
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
import type { MentionStyleProperties } from './spec/EnrichedTextInputNativeComponent';
import { normalizeHtmlStyle } from './utils/normalizeHtmlStyle';

type HeadingStyle = {
  fontSize?: number;
  bold?: boolean;
};

export interface EnrichedTextHtmlStyle {
  h1?: HeadingStyle;
  h2?: HeadingStyle;
  h3?: HeadingStyle;
  h4?: HeadingStyle;
  h5?: HeadingStyle;
  h6?: HeadingStyle;
  blockquote?: {
    borderColor?: ColorValue;
    borderWidth?: number;
    gapWidth?: number;
    color?: ColorValue;
  };
  codeblock?: {
    color?: ColorValue;
    borderRadius?: number;
    backgroundColor?: ColorValue;
  };
  code?: {
    color?: ColorValue;
    backgroundColor?: ColorValue;
  };
  a?: {
    color?: ColorValue;
    textDecorationLine?: 'underline' | 'none';
  };
  mention?: Record<string, MentionStyleProperties> | MentionStyleProperties;
  ol?: {
    gapWidth?: number;
    marginLeft?: number;
    markerFontWeight?: TextStyle['fontWeight'];
    markerColor?: ColorValue;
  };
  ul?: {
    bulletColor?: ColorValue;
    bulletSize?: number;
    marginLeft?: number;
    gapWidth?: number;
  };
}

export interface EnrichedTextInstance extends NativeMethods {}

export interface EnrichedTextProps extends Omit<ViewProps, 'children'> {
  ref?: RefObject<EnrichedTextInstance | null>;
  text: string;
  style?: TextStyle;
  htmlStyle: EnrichedTextHtmlStyle;
  ellipsizeMode?: 'head' | 'middle' | 'tail' | 'clip';
  numberOfLines?: number;
  selectable?: boolean;
  selectionColor?: ColorValue;
}

type ComponentType = (Component<NativeProps, {}, any> & NativeMethods) | null;

export const EnrichedText = ({
  ref,
  text,
  style,
  htmlStyle: _htmlStyle = {},
  ellipsizeMode = 'tail',
  numberOfLines = 0,
  selectable = false,
  selectionColor,
  ...rest
}: EnrichedTextProps) => {
  const nativeRef = useRef<ComponentType | null>(null);

  // TODO: eliminate need to specify mention indicators here
  const htmlStyle = useMemo(
    () => normalizeHtmlStyle(_htmlStyle, ['@']),
    [_htmlStyle]
  );

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
      htmlStyle={htmlStyle}
      ellipsizeMode={ellipsizeMode}
      numberOfLines={numberOfLines}
      selectable={selectable}
      selectionColor={selectionColor}
      {...rest}
    />
  );
};
