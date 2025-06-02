import codegenNativeComponent from 'react-native/Libraries/Utilities/codegenNativeComponent';
import codegenNativeCommands from 'react-native/Libraries/Utilities/codegenNativeCommands';
import type {
  DirectEventHandler,
  Float,
  Int32,
} from 'react-native/Libraries/Types/CodegenTypes';
import type { ColorValue, HostComponent, ViewProps } from 'react-native';
import React from 'react';

export interface OnChangeTextEvent {
  value: string;
}

export interface OnChangeHtmlEvent {
  value: string;
}

export interface OnChangeStateEvent {
  isBold: boolean;
  isItalic: boolean;
  isUnderline: boolean;
  isStrikeThrough: boolean;
  isInlineCode: boolean;
  isH1: boolean;
  isH2: boolean;
  isH3: boolean;
  isCodeBlock: boolean;
  isBlockQuote: boolean;
  isOrderedList: boolean;
  isUnorderedList: boolean;
  isLink: boolean;
  isImage: boolean;
  isMention: boolean;
}

export interface OnPressLink {
  url: string;
}

export interface OnLinkDetectedEvent {
  text: string;
  url: string;
}

export interface OnMentionEvent {
  indicator: string;
  text: string | null;
}

// Codegen does not support `Record<string, string>` yet, so we use `string` which is JSON.parsed later
export interface OnPressMentionEventInternal {
  text: string;
  attributes: string;
}

export interface OnPressMention {
  text: string;
  attributes: Record<string, string>;
}

export interface OnChangeSelectionEvent {
  start: Int32;
  end: Int32;
  text: string;
}

export interface RichTextStyle {
  h1?: {
    fontSize?: Float;
  };
  h2?: {
    fontSize?: Float;
  };
  h3?: {
    fontSize?: Float;
  };
  blockquote?: {
    borderColor?: ColorValue;
    borderWidth?: Float;
    gapWidth?: Float;
  };
  codeblock?: {
    color?: ColorValue;
    borderRadius?: Float;
    backgroundColor?: ColorValue;
  };
  code?: {
    color?: ColorValue;
    backgroundColor?: ColorValue;
  };
  a?: {
    color?: ColorValue;
    textDecorationLine?: string;
  };
  mention?: {
    color?: ColorValue;
    backgroundColor?: ColorValue;
    textDecorationLine?: string;
  };
  img?: {
    width?: Float;
    height?: Float;
  };
  ol?: {
    gapWidth?: Float;
    marginLeft?: Float;
  };
  ul?: {
    bulletColor?: ColorValue;
    bulletSize?: Float;
    marginLeft?: Float;
    gapWidth?: Float;
  };
}

export interface NativeProps extends ViewProps {
  // base props
  autoFocus?: boolean;
  editable?: boolean;
  defaultValue?: string;
  placeholder?: string;
  placeholderTextColor?: ColorValue;
  mentionIndicators: string[];
  cursorColor?: ColorValue;
  selectionColor?: ColorValue;
  richTextStyle?: RichTextStyle;

  // event callbacks
  onInputFocus?: DirectEventHandler<null>;
  onInputBlur?: DirectEventHandler<null>;
  onChangeText?: DirectEventHandler<OnChangeTextEvent>;
  onChangeHtml?: DirectEventHandler<OnChangeHtmlEvent>;
  onChangeState?: DirectEventHandler<OnChangeStateEvent>;
  onPressLink?: DirectEventHandler<OnPressLink>;
  onLinkDetected?: DirectEventHandler<OnLinkDetectedEvent>;
  onMention?: DirectEventHandler<OnMentionEvent>;
  onPressMention?: DirectEventHandler<OnPressMentionEventInternal>;
  onChangeSelection?: DirectEventHandler<OnChangeSelectionEvent>;

  // Style related props - used for generating proper setters in component's manager
  // These should not be passed as regular props
  color?: ColorValue;
  fontSize?: Float;
  fontFamily?: string;
  fontWeight?: string;
  fontStyle?: string;
}

type ComponentType = HostComponent<NativeProps>;

interface NativeCommands {
  // General commands
  focus: (viewRef: React.ElementRef<ComponentType>) => void;
  blur: (viewRef: React.ElementRef<ComponentType>) => void;
  setValue: (viewRef: React.ElementRef<ComponentType>, text: string) => void;

  // Text formatting commands
  toggleBold: (viewRef: React.ElementRef<ComponentType>) => void;
  toggleItalic: (viewRef: React.ElementRef<ComponentType>) => void;
  toggleUnderline: (viewRef: React.ElementRef<ComponentType>) => void;
  toggleStrikeThrough: (viewRef: React.ElementRef<ComponentType>) => void;
  toggleInlineCode: (viewRef: React.ElementRef<ComponentType>) => void;
  toggleH1: (viewRef: React.ElementRef<ComponentType>) => void;
  toggleH2: (viewRef: React.ElementRef<ComponentType>) => void;
  toggleH3: (viewRef: React.ElementRef<ComponentType>) => void;
  toggleCodeBlock: (viewRef: React.ElementRef<ComponentType>) => void;
  toggleBlockQuote: (viewRef: React.ElementRef<ComponentType>) => void;
  toggleOrderedList: (viewRef: React.ElementRef<ComponentType>) => void;
  toggleUnorderedList: (viewRef: React.ElementRef<ComponentType>) => void;
  addLink: (
    viewRef: React.ElementRef<ComponentType>,
    start: Int32,
    end: Int32,
    text: string,
    url: string
  ) => void;
  addImage: (viewRef: React.ElementRef<ComponentType>, uri: string) => void;
  startMention: (
    viewRef: React.ElementRef<ComponentType>,
    indicator: string
  ) => void;
  addMention: (
    viewRef: React.ElementRef<ComponentType>,
    text: string,
    payload: string
  ) => void;
}

export const Commands: NativeCommands = codegenNativeCommands<NativeCommands>({
  supportedCommands: [
    // General commands
    'focus',
    'blur',
    'setValue',

    // Text formatting commands
    'toggleBold',
    'toggleItalic',
    'toggleUnderline',
    'toggleStrikeThrough',
    'toggleInlineCode',
    'toggleH1',
    'toggleH2',
    'toggleH3',
    'toggleCodeBlock',
    'toggleBlockQuote',
    'toggleOrderedList',
    'toggleUnorderedList',
    'addLink',
    'addImage',
    'startMention',
    'addMention',
  ],
});

export default codegenNativeComponent<NativeProps>(
  'ReactNativeRichTextEditorView',
  {
    interfaceOnly: true,
  }
) as HostComponent<NativeProps>;
