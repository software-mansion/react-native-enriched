import {
  type Component,
  type RefObject,
  useImperativeHandle,
  useRef,
} from 'react';
import ReactNativeRichTextEditorView, {
  Commands,
  type NativeProps,
  type OnChangeHtmlEvent,
  type OnChangeStateEvent,
  type OnChangeTextEvent,
  type OnLinkDetectedEvent,
  type OnMentionEvent,
  type OnPressLinkEvent,
  type OnPressMentionEvent,
} from './ReactNativeRichTextEditorViewNativeComponent';
import type {
  ColorValue,
  HostInstance,
  MeasureInWindowOnSuccessCallback,
  MeasureLayoutOnSuccessCallback,
  MeasureOnSuccessCallback,
  NativeMethods,
  NativeSyntheticEvent,
  TextStyle,
  ViewProps,
  ViewStyle,
} from 'react-native';

export interface RichTextInputInstance extends NativeMethods {
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
  toggleCodeBlock: () => void;
  toggleBlockQuote: () => void;
  toggleOrderedList: () => void;
  toggleUnorderedList: () => void;
  setLink: (text: string, url: string) => void;
  setImage: (src: string) => void;
  startMention: (indicator: string) => void;
  setMention: (indicator: string, text: string, value: string) => void;
}

export interface OnChangeMentionEvent {
  indicator: string;
  text: string;
}

export interface RichTextInputProps extends Omit<ViewProps, 'children'> {
  ref?: RefObject<RichTextInputInstance | null>;
  autoFocus?: boolean;
  mentionIndicators?: string[];
  defaultValue?: string;
  placeholder?: string;
  placeholderTextColor?: ColorValue;
  cursorColor?: ColorValue;
  selectionColor?: ColorValue;
  style?: ViewStyle | TextStyle;
  onChangeText?: (e: NativeSyntheticEvent<OnChangeTextEvent>) => void;
  onChangeHtml?: (e: NativeSyntheticEvent<OnChangeHtmlEvent>) => void;
  onChangeState?: (e: NativeSyntheticEvent<OnChangeStateEvent>) => void;
  onPressLink?: (e: NativeSyntheticEvent<OnPressLinkEvent>) => void;
  onLinkDetected?: (e: NativeSyntheticEvent<OnLinkDetectedEvent>) => void;
  onStartMention?: (indicator: string) => void;
  onChangeMention?: (e: OnChangeMentionEvent) => void;
  onEndMention?: (indicator: string) => void;
  onPressMention?: (e: NativeSyntheticEvent<OnPressMentionEvent>) => void;
}

const nullthrows = <T,>(value: T | null | undefined): T => {
  if (value == null) {
    throw new Error('Unexpected null or undefined value');
  }

  return value;
};

const warnAboutMissconfiguredMentions = (indicator: string) => {
  console.warn(
    `Looks like you are trying to set a "${indicator}" but it's not in the mentionIndicators prop`
  );
};

type ComponentType = (Component<NativeProps, {}, any> & NativeMethods) | null;

export const RichTextInput = ({
  ref,
  autoFocus,
  mentionIndicators = ['@'],
  defaultValue,
  placeholder,
  placeholderTextColor,
  cursorColor,
  selectionColor,
  style,
  onChangeText,
  onChangeHtml,
  onChangeState,
  onPressLink,
  onLinkDetected,
  onStartMention,
  onChangeMention,
  onEndMention,
  onPressMention,
  ...rest
}: RichTextInputProps) => {
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
    toggleCodeBlock: () => {
      Commands.toggleCodeBlock(nullthrows(nativeRef.current));
    },
    toggleBlockQuote: () => {
      Commands.toggleBlockQuote(nullthrows(nativeRef.current));
    },
    toggleOrderedList: () => {
      Commands.toggleOrderedList(nullthrows(nativeRef.current));
    },
    toggleUnorderedList: () => {
      Commands.toggleUnorderedList(nullthrows(nativeRef.current));
    },
    setLink: (text: string, url: string) => {
      Commands.addLink(nullthrows(nativeRef.current), text, url);
    },
    setImage: (uri: string) => {
      Commands.addImage(nullthrows(nativeRef.current), uri);
    },
    setMention: (indicator: string, text: string, value: string) => {
      if (!mentionIndicators?.includes(indicator)) {
        warnAboutMissconfiguredMentions(indicator);
      }

      Commands.addMention(
        nullthrows(nativeRef.current),
        indicator,
        text,
        value
      );
    },
    startMention: (indicator: string) => {
      if (!mentionIndicators?.includes(indicator)) {
        warnAboutMissconfiguredMentions(indicator);
      }

      Commands.startMention(nullthrows(nativeRef.current), indicator);
    },
  }));

  const handleMentionEvent = (e: NativeSyntheticEvent<OnMentionEvent>) => {
    const mentionText = e.nativeEvent.text;
    const mentionIndicator = e.nativeEvent.indicator;

    switch (mentionText) {
      case '':
        onStartMention?.(mentionIndicator);
        break;
      case null:
        onEndMention?.(mentionIndicator);
        break;
      default:
        onChangeMention?.({ indicator: mentionIndicator, text: mentionText });
        break;
    }
  };

  return (
    <ReactNativeRichTextEditorView
      ref={nativeRef}
      mentionIndicators={mentionIndicators}
      autoFocus={autoFocus}
      defaultValue={defaultValue}
      placeholder={placeholder}
      placeholderTextColor={placeholderTextColor}
      cursorColor={cursorColor}
      selectionColor={selectionColor}
      style={style}
      onChangeText={onChangeText}
      onChangeHtml={onChangeHtml}
      onChangeState={onChangeState}
      onPressLink={onPressLink}
      onLinkDetected={onLinkDetected}
      onMention={handleMentionEvent}
      onPressMention={onPressMention}
      {...rest}
    />
  );
};
