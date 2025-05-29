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
  type OnChangeSelectionEvent,
  type OnChangeStateEvent,
  type OnChangeTextEvent,
  type OnLinkDetectedEvent,
  type OnMentionEvent,
  type OnPressLink,
  type OnPressMention,
  type OnPressMentionEventInternal,
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
  setValue: (value: string) => void;

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
  setLink: (start: number, end: number, text: string, url: string) => void;
  setImage: (src: string) => void;
  startMention: (indicator: string) => void;
  setMention: (text: string, attributes?: Record<string, string>) => void;
}

export interface OnChangeMentionEvent {
  indicator: string;
  text: string;
}

export interface RichTextInputProps extends Omit<ViewProps, 'children'> {
  ref?: RefObject<RichTextInputInstance | null>;
  autoFocus?: boolean;
  editable?: boolean;
  mentionIndicators?: string[];
  defaultValue?: string;
  placeholder?: string;
  placeholderTextColor?: ColorValue;
  cursorColor?: ColorValue;
  selectionColor?: ColorValue;
  style?: ViewStyle | TextStyle;
  onFocus?: () => void;
  onBlur?: () => void;
  onChangeText?: (e: NativeSyntheticEvent<OnChangeTextEvent>) => void;
  onChangeHtml?: (e: NativeSyntheticEvent<OnChangeHtmlEvent>) => void;
  onChangeState?: (e: NativeSyntheticEvent<OnChangeStateEvent>) => void;
  onPressLink?: (e: OnPressLink) => void;
  onLinkDetected?: (e: NativeSyntheticEvent<OnLinkDetectedEvent>) => void;
  onStartMention?: (indicator: string) => void;
  onChangeMention?: (e: OnChangeMentionEvent) => void;
  onEndMention?: (indicator: string) => void;
  onPressMention?: (e: OnPressMention) => void;
  onChangeSelection?: (e: NativeSyntheticEvent<OnChangeSelectionEvent>) => void;
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
  editable = true,
  mentionIndicators = ['@'],
  defaultValue,
  placeholder,
  placeholderTextColor,
  cursorColor,
  selectionColor,
  style,
  onFocus,
  onBlur,
  onChangeText,
  onChangeHtml,
  onChangeState,
  onPressLink,
  onLinkDetected,
  onStartMention,
  onChangeMention,
  onEndMention,
  onPressMention,
  onChangeSelection,
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
    setValue: (value: string) => {
      Commands.setValue(nullthrows(nativeRef.current), value);
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
    setLink: (start: number, end: number, text: string, url: string) => {
      Commands.addLink(nullthrows(nativeRef.current), start, end, text, url);
    },
    setImage: (uri: string) => {
      Commands.addImage(nullthrows(nativeRef.current), uri);
    },
    setMention: (text: string, attributes?: Record<string, string>) => {
      // Codegen does not support objects as Commands parameters, so we stringify attributes
      const parsedAttributes = JSON.stringify(attributes ?? {});

      Commands.addMention(
        nullthrows(nativeRef.current),
        text,
        parsedAttributes
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

  const handleMentionPress = (
    e: NativeSyntheticEvent<OnPressMentionEventInternal>
  ) => {
    const { text, attributes } = e.nativeEvent;
    const parsedAttributes = JSON.parse(attributes) as Record<string, string>;

    onPressMention?.({ text, attributes: parsedAttributes });
  };

  const handleLinkPress = (e: NativeSyntheticEvent<OnPressLink>) => {
    onPressLink?.({ url: e.nativeEvent.url });
  };

  return (
    <ReactNativeRichTextEditorView
      ref={nativeRef}
      mentionIndicators={mentionIndicators}
      editable={editable}
      autoFocus={autoFocus}
      defaultValue={defaultValue}
      placeholder={placeholder}
      placeholderTextColor={placeholderTextColor}
      cursorColor={cursorColor}
      selectionColor={selectionColor}
      style={style}
      onInputFocus={onFocus}
      onInputBlur={onBlur}
      onChangeText={onChangeText}
      onChangeHtml={onChangeHtml}
      onChangeState={onChangeState}
      onLinkDetected={onLinkDetected}
      onPressLink={handleLinkPress}
      onMention={handleMentionEvent}
      onPressMention={handleMentionPress}
      onChangeSelection={onChangeSelection}
      {...rest}
    />
  );
};
