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
  type OnChangeStyleEvent,
  type OnChangeTextEvent,
  type OnLinkDetectedEvent,
  type OnMentionEvent,
  type OnPressLinkEvent,
  type OnPressMentionEvent,
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
  toggleCodeBlock: () => void;
  toggleBlockQuote: () => void;
  toggleOrderedList: () => void;
  toggleUnorderedList: () => void;
  setLink: (text: string, url: string) => void;
  setImage: (src: string) => void;
  startMention: () => void;
  setMention: (text: string, value: string) => void;
}

export interface OnMentionChangeEvent {
  text: string;
}

export interface RichTextInputProps {
  ref?: RefObject<RichTextInputInstance | null>;
  autoFocus?: boolean;
  defaultValue?: string;
  style?: ViewStyle;
  onChangeText?: (e: NativeSyntheticEvent<OnChangeTextEvent>) => void;
  onChangeHtml?: (e: NativeSyntheticEvent<OnChangeHtmlEvent>) => void;
  onChangeStyle?: (e: NativeSyntheticEvent<OnChangeStyleEvent>) => void;
  onPressLink?: (e: NativeSyntheticEvent<OnPressLinkEvent>) => void;
  onLinkDetected?: (e: NativeSyntheticEvent<OnLinkDetectedEvent>) => void;
  onMentionStart?: () => void;
  onMentionChange?: (e: NativeSyntheticEvent<OnMentionChangeEvent>) => void;
  onMentionEnd?: () => void;
  onPressMention?: (e: NativeSyntheticEvent<OnPressMentionEvent>) => void;
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
  autoFocus,
  defaultValue,
  style,
  onChangeText,
  onChangeHtml,
  onChangeStyle,
  onPressLink,
  onLinkDetected,
  onMentionStart,
  onMentionChange,
  onMentionEnd,
  onPressMention,
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
    setMention: (text: string, value: string) => {
      Commands.addMention(nullthrows(nativeRef.current), text, value);
    },
    startMention: () => {
      Commands.startMention(nullthrows(nativeRef.current));
    },
  }));

  const handleMentionEvent = (e: NativeSyntheticEvent<OnMentionEvent>) => {
    const mentionText = e.nativeEvent.text;

    switch (mentionText) {
      case '':
        onMentionStart?.();
        break;
      case null:
        onMentionEnd?.();
        break;
      default:
        onMentionChange?.(e as NativeSyntheticEvent<OnMentionChangeEvent>);
        break;
    }
  };

  return (
    <ReactNativeRichTextEditorView
      ref={nativeRef}
      autoFocus={autoFocus}
      defaultValue={defaultValue}
      style={style}
      onChangeText={onChangeText}
      onChangeHtml={onChangeHtml}
      onChangeStyle={onChangeStyle}
      onPressLink={onPressLink}
      onLinkDetected={onLinkDetected}
      onMention={handleMentionEvent}
      onPressMention={onPressMention}
    />
  );
};
