import { codegenNativeComponent, codegenNativeCommands } from 'react-native';
import type {
  DirectEventHandler,
  Float,
  Int32,
  UnsafeMixed,
} from 'react-native/Libraries/Types/CodegenTypes';
import type { ColorValue, HostComponent, ViewProps } from 'react-native';
import React from 'react';

export interface LinkNativeRegex {
  pattern: string;
  caseInsensitive: boolean;
  dotAll: boolean;
  // Link detection will be disabled
  isDisabled: boolean;
  // Use default native link regex
  isDefault: boolean;
}

export interface OnChangeTextEvent {
  value: string;
}

export interface OnChangeHtmlEvent {
  value: string;
}

export interface OnChangeStateEvent {
  bold: {
    isActive: boolean;
    isConflicting: boolean;
    isBlocking: boolean;
  };
  italic: {
    isActive: boolean;
    isConflicting: boolean;
    isBlocking: boolean;
  };
  underline: {
    isActive: boolean;
    isConflicting: boolean;
    isBlocking: boolean;
  };
  strikeThrough: {
    isActive: boolean;
    isConflicting: boolean;
    isBlocking: boolean;
  };
  inlineCode: {
    isActive: boolean;
    isConflicting: boolean;
    isBlocking: boolean;
  };
  h1: {
    isActive: boolean;
    isConflicting: boolean;
    isBlocking: boolean;
  };
  h2: {
    isActive: boolean;
    isConflicting: boolean;
    isBlocking: boolean;
  };
  h3: {
    isActive: boolean;
    isConflicting: boolean;
    isBlocking: boolean;
  };
  h4: {
    isActive: boolean;
    isConflicting: boolean;
    isBlocking: boolean;
  };
  h5: {
    isActive: boolean;
    isConflicting: boolean;
    isBlocking: boolean;
  };
  h6: {
    isActive: boolean;
    isConflicting: boolean;
    isBlocking: boolean;
  };
  codeBlock: {
    isActive: boolean;
    isConflicting: boolean;
    isBlocking: boolean;
  };
  blockQuote: {
    isActive: boolean;
    isConflicting: boolean;
    isBlocking: boolean;
  };
  orderedList: {
    isActive: boolean;
    isConflicting: boolean;
    isBlocking: boolean;
  };
  unorderedList: {
    isActive: boolean;
    isConflicting: boolean;
    isBlocking: boolean;
  };
  link: {
    isActive: boolean;
    isConflicting: boolean;
    isBlocking: boolean;
  };
  image: {
    isActive: boolean;
    isConflicting: boolean;
    isBlocking: boolean;
  };
  mention: {
    isActive: boolean;
    isConflicting: boolean;
    isBlocking: boolean;
  };
}

export interface OnChangeStateDeprecatedEvent {
  isBold: boolean;
  isItalic: boolean;
  isUnderline: boolean;
  isStrikeThrough: boolean;
  isInlineCode: boolean;
  isH1: boolean;
  isH2: boolean;
  isH3: boolean;
  isH4: boolean;
  isH5: boolean;
  isH6: boolean;
  isCodeBlock: boolean;
  isBlockQuote: boolean;
  isOrderedList: boolean;
  isUnorderedList: boolean;
  isLink: boolean;
  isImage: boolean;
  isMention: boolean;
}

export interface OnLinkDetected {
  text: string;
  url: string;
  start: Int32;
  end: Int32;
}

export interface OnMentionDetectedInternal {
  text: string;
  indicator: string;
  payload: string;
}

export interface OnMentionDetected {
  text: string;
  indicator: string;
  attributes: Record<string, string>;
}

export interface OnMentionEvent {
  indicator: string;
  text: UnsafeMixed;
}

export interface OnChangeSelectionEvent {
  start: Int32;
  end: Int32;
  text: string;
}

export interface OnRequestHtmlResultEvent {
  requestId: Int32;
  html: UnsafeMixed;
}

export interface MentionStyleProperties {
  color?: ColorValue;
  backgroundColor?: ColorValue;
  textDecorationLine?: 'underline' | 'none';
}

export interface OnKeyPressEvent {
  key: string;
}

export interface OnPasteImagesEvent {
  images: {
    uri: string;
    type: string;
    width: Float;
    height: Float;
  }[];
}

type Heading = {
  fontSize?: Float;
  bold?: boolean;
};

export interface HtmlStyleInternal {
  h1?: Heading;
  h2?: Heading;
  h3?: Heading;
  h4?: Heading;
  h5?: Heading;
  h6?: Heading;
  blockquote?: {
    borderColor?: ColorValue;
    borderWidth?: Float;
    gapWidth?: Float;
    color?: ColorValue;
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
  // This is a workaround for the fact that codegen does not support Records.
  // On native Android side this will become a ReadableMap, on native iOS we can work with a folly::dynamic object.
  mention?: UnsafeMixed;
  ol?: {
    gapWidth?: Float;
    marginLeft?: Float;
    markerFontWeight?: string;
    markerColor?: ColorValue;
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
  autoCapitalize?: string;
  htmlStyle?: HtmlStyleInternal;
  scrollEnabled?: boolean;
  linkRegex?: LinkNativeRegex;

  // event callbacks
  onInputFocus?: DirectEventHandler<null>;
  onInputBlur?: DirectEventHandler<null>;
  onChangeText?: DirectEventHandler<OnChangeTextEvent>;
  onChangeHtml?: DirectEventHandler<OnChangeHtmlEvent>;
  onChangeState?: DirectEventHandler<OnChangeStateEvent>;
  onChangeStateDeprecated?: DirectEventHandler<OnChangeStateDeprecatedEvent>;
  onLinkDetected?: DirectEventHandler<OnLinkDetected>;
  onMentionDetected?: DirectEventHandler<OnMentionDetectedInternal>;
  onMention?: DirectEventHandler<OnMentionEvent>;
  onChangeSelection?: DirectEventHandler<OnChangeSelectionEvent>;
  onRequestHtmlResult?: DirectEventHandler<OnRequestHtmlResultEvent>;
  onInputKeyPress?: DirectEventHandler<OnKeyPressEvent>;
  onPasteImages?: DirectEventHandler<OnPasteImagesEvent>;

  // Style related props - used for generating proper setters in component's manager
  // These should not be passed as regular props
  color?: ColorValue;
  fontSize?: Float;
  fontFamily?: string;
  fontWeight?: string;
  fontStyle?: string;

  // Used for onChangeHtml event performance optimization
  isOnChangeHtmlSet: boolean;
  // Used for onChangeText event performance optimization
  isOnChangeTextSet: boolean;

  // Experimental
  androidExperimentalSynchronousEvents: boolean;
}

type ComponentType = HostComponent<NativeProps>;

interface NativeCommands {
  // General commands
  focus: (viewRef: React.ElementRef<ComponentType>) => void;
  blur: (viewRef: React.ElementRef<ComponentType>) => void;
  setValue: (viewRef: React.ElementRef<ComponentType>, text: string) => void;
  setSelection: (
    viewRef: React.ElementRef<ComponentType>,
    start: Int32,
    end: Int32
  ) => void;

  // Text formatting commands
  toggleBold: (viewRef: React.ElementRef<ComponentType>) => void;
  toggleItalic: (viewRef: React.ElementRef<ComponentType>) => void;
  toggleUnderline: (viewRef: React.ElementRef<ComponentType>) => void;
  toggleStrikeThrough: (viewRef: React.ElementRef<ComponentType>) => void;
  toggleInlineCode: (viewRef: React.ElementRef<ComponentType>) => void;
  toggleH1: (viewRef: React.ElementRef<ComponentType>) => void;
  toggleH2: (viewRef: React.ElementRef<ComponentType>) => void;
  toggleH3: (viewRef: React.ElementRef<ComponentType>) => void;
  toggleH4: (viewRef: React.ElementRef<ComponentType>) => void;
  toggleH5: (viewRef: React.ElementRef<ComponentType>) => void;
  toggleH6: (viewRef: React.ElementRef<ComponentType>) => void;
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
  addImage: (
    viewRef: React.ElementRef<ComponentType>,
    uri: string,
    width: Float,
    height: Float
  ) => void;
  startMention: (
    viewRef: React.ElementRef<ComponentType>,
    indicator: string
  ) => void;
  addMention: (
    viewRef: React.ElementRef<ComponentType>,
    indicator: string,
    text: string,
    payload: string
  ) => void;
  requestHTML: (
    viewRef: React.ElementRef<ComponentType>,
    requestId: Int32
  ) => void;
}

export const Commands: NativeCommands = codegenNativeCommands<NativeCommands>({
  supportedCommands: [
    // General commands
    'focus',
    'blur',
    'setValue',
    'setSelection',

    // Text formatting commands
    'toggleBold',
    'toggleItalic',
    'toggleUnderline',
    'toggleStrikeThrough',
    'toggleInlineCode',
    'toggleH1',
    'toggleH2',
    'toggleH3',
    'toggleH4',
    'toggleH5',
    'toggleH6',
    'toggleCodeBlock',
    'toggleBlockQuote',
    'toggleOrderedList',
    'toggleUnorderedList',
    'addLink',
    'addImage',
    'startMention',
    'addMention',
    'requestHTML',
  ],
});

export default codegenNativeComponent<NativeProps>('EnrichedTextInputView', {
  interfaceOnly: true,
}) as HostComponent<NativeProps>;
