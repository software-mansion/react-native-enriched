import { codegenNativeComponent, codegenNativeCommands } from 'react-native';
import type {
  CodegenTypes,
  ColorValue,
  HostComponent,
  ViewProps,
} from 'react-native';

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
  checkboxList: {
    isActive: boolean;
    isConflicting: boolean;
    isBlocking: boolean;
  };
  alignment: string;
}

export interface OnLinkDetected {
  text: string;
  url: string;
  start: CodegenTypes.Int32;
  end: CodegenTypes.Int32;
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
  text: CodegenTypes.UnsafeMixed;
}

export interface OnChangeSelectionEvent {
  start: CodegenTypes.Int32;
  end: CodegenTypes.Int32;
  text: string;
}

export interface OnRequestHtmlResultEvent {
  requestId: CodegenTypes.Int32;
  html: CodegenTypes.UnsafeMixed;
}

export interface OnSubmitEditing {
  text: string;
}

export interface OnKeyPressEvent {
  key: string;
}

export interface ContextMenuItemConfig {
  text: string;
}

export interface TextShortcut {
  trigger: string;
  style: string;
}

export interface OnContextMenuItemPressEvent {
  itemText: string;
  selectedText: string;
  selectionStart: CodegenTypes.Int32;
  selectionEnd: CodegenTypes.Int32;
  styleState: {
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
    checkboxList: {
      isActive: boolean;
      isConflicting: boolean;
      isBlocking: boolean;
    };
    alignment: string;
  };
}

interface TargetedEvent {
  target: CodegenTypes.Int32;
}

export interface PastedImage {
  uri: string;
  type: string;
  width: CodegenTypes.Float;
  height: CodegenTypes.Float;
}

export interface OnPasteImagesEvent {
  images: {
    uri: string;
    type: string;
    width: CodegenTypes.Float;
    height: CodegenTypes.Float;
  }[];
}

type Heading = {
  fontSize?: CodegenTypes.Float;
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
    borderWidth?: CodegenTypes.Float;
    gapWidth?: CodegenTypes.Float;
    color?: ColorValue;
  };
  codeblock?: {
    color?: ColorValue;
    borderRadius?: CodegenTypes.Float;
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
  mention?: CodegenTypes.UnsafeMixed;
  ol?: {
    gapWidth?: CodegenTypes.Float;
    marginLeft?: CodegenTypes.Float;
    markerFontWeight?: string;
    markerColor?: ColorValue;
  };
  ul?: {
    bulletColor?: ColorValue;
    bulletSize?: CodegenTypes.Float;
    marginLeft?: CodegenTypes.Float;
    gapWidth?: CodegenTypes.Float;
  };
  ulCheckbox?: {
    gapWidth?: CodegenTypes.Float;
    boxSize?: CodegenTypes.Float;
    marginLeft?: CodegenTypes.Float;
    boxColor?: ColorValue;
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
  contextMenuItems?: ReadonlyArray<Readonly<ContextMenuItemConfig>>;
  textShortcuts: ReadonlyArray<Readonly<TextShortcut>>;
  returnKeyType?: string;
  returnKeyLabel?: string;
  submitBehavior?: string;
  allowFontScaling?: boolean;

  // event callbacks
  onInputFocus?: CodegenTypes.DirectEventHandler<TargetedEvent>;
  onInputBlur?: CodegenTypes.DirectEventHandler<TargetedEvent>;
  onChangeText?: CodegenTypes.DirectEventHandler<OnChangeTextEvent>;
  onChangeHtml?: CodegenTypes.DirectEventHandler<OnChangeHtmlEvent>;
  onChangeState?: CodegenTypes.DirectEventHandler<OnChangeStateEvent>;
  onLinkDetected?: CodegenTypes.DirectEventHandler<OnLinkDetected>;
  onMentionDetected?: CodegenTypes.DirectEventHandler<OnMentionDetectedInternal>;
  onMention?: CodegenTypes.DirectEventHandler<OnMentionEvent>;
  onChangeSelection?: CodegenTypes.DirectEventHandler<OnChangeSelectionEvent>;
  onRequestHtmlResult?: CodegenTypes.DirectEventHandler<OnRequestHtmlResultEvent>;
  onInputKeyPress?: CodegenTypes.DirectEventHandler<OnKeyPressEvent>;
  onPasteImages?: CodegenTypes.DirectEventHandler<OnPasteImagesEvent>;
  onContextMenuItemPress?: CodegenTypes.DirectEventHandler<OnContextMenuItemPressEvent>;
  onSubmitEditing?: CodegenTypes.BubblingEventHandler<OnSubmitEditing>;

  // Style related props - used for generating proper setters in component's manager
  // These should not be passed as regular props
  color?: ColorValue;
  fontSize?: CodegenTypes.Float;
  lineHeight?: CodegenTypes.Float;
  fontFamily?: string;
  fontWeight?: string;
  fontStyle?: string;

  // Used for onChangeHtml event performance optimization
  isOnChangeHtmlSet: boolean;
  // Used for onChangeText event performance optimization
  isOnChangeTextSet: boolean;

  // Experimental
  androidExperimentalSynchronousEvents: boolean;
  useHtmlNormalizer: boolean;
}

type ComponentType = HostComponent<NativeProps>;

interface NativeCommands {
  // General commands
  focus: (viewRef: React.ComponentRef<ComponentType>) => void;
  blur: (viewRef: React.ComponentRef<ComponentType>) => void;
  setValue: (viewRef: React.ComponentRef<ComponentType>, text: string) => void;
  setSelection: (
    viewRef: React.ComponentRef<ComponentType>,
    start: CodegenTypes.Int32,
    end: CodegenTypes.Int32
  ) => void;

  // Text formatting commands
  toggleBold: (viewRef: React.ComponentRef<ComponentType>) => void;
  toggleItalic: (viewRef: React.ComponentRef<ComponentType>) => void;
  toggleUnderline: (viewRef: React.ComponentRef<ComponentType>) => void;
  toggleStrikeThrough: (viewRef: React.ComponentRef<ComponentType>) => void;
  toggleInlineCode: (viewRef: React.ComponentRef<ComponentType>) => void;
  toggleH1: (viewRef: React.ComponentRef<ComponentType>) => void;
  toggleH2: (viewRef: React.ComponentRef<ComponentType>) => void;
  toggleH3: (viewRef: React.ComponentRef<ComponentType>) => void;
  toggleH4: (viewRef: React.ComponentRef<ComponentType>) => void;
  toggleH5: (viewRef: React.ComponentRef<ComponentType>) => void;
  toggleH6: (viewRef: React.ComponentRef<ComponentType>) => void;
  toggleCodeBlock: (viewRef: React.ComponentRef<ComponentType>) => void;
  toggleBlockQuote: (viewRef: React.ComponentRef<ComponentType>) => void;
  toggleOrderedList: (viewRef: React.ComponentRef<ComponentType>) => void;
  toggleUnorderedList: (viewRef: React.ComponentRef<ComponentType>) => void;
  toggleCheckboxList: (
    viewRef: React.ComponentRef<ComponentType>,
    checked: boolean
  ) => void;
  addLink: (
    viewRef: React.ComponentRef<ComponentType>,
    start: CodegenTypes.Int32,
    end: CodegenTypes.Int32,
    text: string,
    url: string
  ) => void;
  removeLink: (
    viewRef: React.ComponentRef<ComponentType>,
    start: CodegenTypes.Int32,
    end: CodegenTypes.Int32
  ) => void;
  addImage: (
    viewRef: React.ComponentRef<ComponentType>,
    uri: string,
    width: CodegenTypes.Float,
    height: CodegenTypes.Float
  ) => void;
  startMention: (
    viewRef: React.ComponentRef<ComponentType>,
    indicator: string
  ) => void;
  addMention: (
    viewRef: React.ComponentRef<ComponentType>,
    indicator: string,
    text: string,
    payload: string
  ) => void;
  requestHTML: (
    viewRef: React.ComponentRef<ComponentType>,
    requestId: CodegenTypes.Int32
  ) => void;
  setTextAlignment: (
    viewRef: React.ComponentRef<ComponentType>,
    alignment: string
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
    'toggleCheckboxList',
    'addLink',
    'removeLink',
    'addImage',
    'startMention',
    'addMention',
    'requestHTML',
    'setTextAlignment',
  ],
});

export default codegenNativeComponent<NativeProps>('EnrichedTextInputView', {
  interfaceOnly: true,
}) as HostComponent<NativeProps>;
