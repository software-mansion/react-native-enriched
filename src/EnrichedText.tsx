import {
  type Component,
  type RefObject,
  useCallback,
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
  type OnLinkPressEvent,
  type OnMentionPressEvent,
  type OnMentionPressEventInternal,
} from './spec/EnrichedTextNativeComponent';
import { nullthrows } from './utils/nullthrows';
import { normalizeEnrichedTextHtmlStyle } from './utils/normalizeHtmlStyle';
import type { EnrichedTextHtmlStyle } from './types';
import type { DirectEventHandler } from 'react-native/Libraries/Types/CodegenTypes';

export interface EnrichedTextInstance extends NativeMethods {}

export interface EnrichedTextProps extends ViewProps {
  ref?: RefObject<EnrichedTextInstance | null>;
  children: string;
  style?: TextStyle;
  htmlStyle?: EnrichedTextHtmlStyle;
  ellipsizeMode?: 'head' | 'middle' | 'tail' | 'clip';
  numberOfLines?: number;
  selectable?: boolean;
  selectionColor?: ColorValue;
  onLinkPress?: (event: OnLinkPressEvent) => void;
  onMentionPress?: (event: OnMentionPressEvent) => void;
}

type ComponentType = (Component<NativeProps, {}, any> & NativeMethods) | null;

export const EnrichedText = ({
  ref,
  children,
  style,
  htmlStyle: _htmlStyle = {},
  ellipsizeMode = 'tail',
  numberOfLines = 0,
  selectable = false,
  selectionColor,
  onLinkPress: _onLinkPress,
  onMentionPress: _onMentionPress,
  ...rest
}: EnrichedTextProps) => {
  const nativeRef = useRef<ComponentType | null>(null);

  const htmlStyle = useMemo(
    () => normalizeEnrichedTextHtmlStyle(_htmlStyle),
    [_htmlStyle]
  );

  const onLinkPress: DirectEventHandler<OnLinkPressEvent> = useCallback(
    (e) => {
      _onLinkPress?.(e.nativeEvent);
    },
    [_onLinkPress]
  );

  const onMentionPress: DirectEventHandler<OnMentionPressEventInternal> =
    useCallback(
      (e) => {
        const { text, indicator, attributes } = e.nativeEvent;
        _onMentionPress?.({
          text,
          indicator,
          attributes: attributes as Record<string, string>,
        });
      },
      [_onMentionPress]
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
      text={children}
      style={style}
      htmlStyle={htmlStyle}
      ellipsizeMode={ellipsizeMode}
      numberOfLines={numberOfLines}
      selectable={selectable}
      selectionColor={selectionColor}
      onLinkPress={onLinkPress}
      onMentionPress={onMentionPress}
      {...rest}
    />
  );
};
