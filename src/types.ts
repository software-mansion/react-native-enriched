import type { RefObject } from 'react';
import type {
  ColorValue,
  DimensionValue,
  NativeMethods,
  NativeSyntheticEvent,
  ReturnKeyTypeOptions,
  TargetedEvent,
  TextStyle,
  ViewProps,
  ViewStyle,
} from 'react-native';

export interface EnrichedInputStyle {
  // Layout / FlexStyle
  alignSelf?: TextStyle['alignSelf'];
  aspectRatio?: number | string;
  borderBottomWidth?: number;
  borderEndWidth?: number;
  borderLeftWidth?: number;
  borderRightWidth?: number;
  borderStartWidth?: number;
  borderTopWidth?: number;
  borderWidth?: number;
  bottom?: DimensionValue;
  boxSizing?: TextStyle['boxSizing'];
  display?: TextStyle['display'];
  end?: DimensionValue;
  flex?: number;
  flexBasis?: DimensionValue;
  flexGrow?: number;
  flexShrink?: number;
  height?: DimensionValue;
  inset?: DimensionValue;
  insetBlock?: DimensionValue;
  insetBlockEnd?: DimensionValue;
  insetBlockStart?: DimensionValue;
  insetInline?: DimensionValue;
  insetInlineEnd?: DimensionValue;
  insetInlineStart?: DimensionValue;
  left?: DimensionValue;
  margin?: DimensionValue;
  marginBlock?: DimensionValue;
  marginBlockEnd?: DimensionValue;
  marginBlockStart?: DimensionValue;
  marginBottom?: DimensionValue;
  marginEnd?: DimensionValue;
  marginHorizontal?: DimensionValue;
  marginInline?: DimensionValue;
  marginInlineEnd?: DimensionValue;
  marginInlineStart?: DimensionValue;
  marginLeft?: DimensionValue;
  marginRight?: DimensionValue;
  marginStart?: DimensionValue;
  marginTop?: DimensionValue;
  marginVertical?: DimensionValue;
  maxHeight?: DimensionValue;
  maxWidth?: DimensionValue;
  minHeight?: DimensionValue;
  minWidth?: DimensionValue;
  padding?: DimensionValue;
  paddingBlock?: DimensionValue;
  paddingBlockEnd?: DimensionValue;
  paddingBlockStart?: DimensionValue;
  paddingBottom?: DimensionValue;
  paddingEnd?: DimensionValue;
  paddingHorizontal?: DimensionValue;
  paddingInline?: DimensionValue;
  paddingInlineEnd?: DimensionValue;
  paddingInlineStart?: DimensionValue;
  paddingLeft?: DimensionValue;
  paddingRight?: DimensionValue;
  paddingStart?: DimensionValue;
  paddingTop?: DimensionValue;
  paddingVertical?: DimensionValue;
  position?: TextStyle['position'];
  right?: DimensionValue;
  start?: DimensionValue;
  top?: DimensionValue;
  width?: DimensionValue;
  zIndex?: number;

  // Shadows
  /** @platform ios */
  shadowColor?: ColorValue;
  /** @platform ios */
  shadowOffset?: TextStyle['shadowOffset'];
  /** @platform ios */
  shadowOpacity?: TextStyle['shadowOpacity'];
  /** @platform ios */
  shadowRadius?: number;

  // Transforms
  transform?: TextStyle['transform'];
  transformOrigin?: TextStyle['transformOrigin'];

  // View appearance
  /** @platform ios web */
  backfaceVisibility?: TextStyle['backfaceVisibility'];
  backgroundColor?: ColorValue;
  /** @platform ios web */
  borderBlockColor?: ColorValue;
  /** @platform ios web */
  borderBlockEndColor?: ColorValue;
  /** @platform ios web */
  borderBlockStartColor?: ColorValue;
  /** @platform ios web */
  borderBottomColor?: ColorValue;
  /** @platform ios web */
  borderBottomEndRadius?: TextStyle['borderBottomEndRadius'];
  /** @platform ios web */
  borderBottomLeftRadius?: TextStyle['borderBottomLeftRadius'];
  /** @platform ios web */
  borderBottomRightRadius?: TextStyle['borderBottomRightRadius'];
  /** @platform ios web */
  borderBottomStartRadius?: TextStyle['borderBottomStartRadius'];
  /** @platform ios web */
  borderColor?: ColorValue;
  /** @platform ios web */
  borderEndColor?: ColorValue;
  /** @platform ios web */
  borderEndEndRadius?: TextStyle['borderEndEndRadius'];
  /** @platform ios web */
  borderEndStartRadius?: TextStyle['borderEndStartRadius'];
  /** @platform ios web */
  borderLeftColor?: ColorValue;
  /** @platform ios web */
  borderRadius?: TextStyle['borderRadius'];
  /** @platform ios web */
  borderRightColor?: ColorValue;
  /** @platform ios web */
  borderStartColor?: ColorValue;
  /** @platform ios web */
  borderStartEndRadius?: TextStyle['borderStartEndRadius'];
  /** @platform ios web */
  borderStartStartRadius?: TextStyle['borderStartStartRadius'];
  /** @platform ios web */
  borderStyle?: TextStyle['borderStyle'];
  /** @platform ios web */
  borderTopColor?: ColorValue;
  /** @platform ios web */
  borderTopEndRadius?: TextStyle['borderTopEndRadius'];
  /** @platform ios web */
  borderTopLeftRadius?: TextStyle['borderTopLeftRadius'];
  /** @platform ios web */
  borderTopRightRadius?: TextStyle['borderTopRightRadius'];
  /** @platform ios web */
  borderTopStartRadius?: TextStyle['borderTopStartRadius'];
  boxShadow?: TextStyle['boxShadow'];
  /** @platform web */
  cursor?: TextStyle['cursor'];
  /** @platform android */
  elevation?: number;
  /** @platform android web */
  filter?: TextStyle['filter'];
  /** @platform android web */
  mixBlendMode?: TextStyle['mixBlendMode'];
  opacity?: TextStyle['opacity'];
  /** @platform ios web */
  outlineColor?: ColorValue;
  outlineOffset?: TextStyle['outlineOffset'];
  /** @platform android web */
  outlineStyle?: TextStyle['outlineStyle'];
  outlineWidth?: TextStyle['outlineWidth'];
  /** @platform ios web */
  pointerEvents?: TextStyle['pointerEvents'];

  // Typography
  color?: ColorValue;
  fontFamily?: string;
  fontSize?: number;
  fontStyle?: TextStyle['fontStyle'];
  fontWeight?: TextStyle['fontWeight'];
  lineHeight?: number;
  /** @platform web */
  letterSpacing?: number;
}

interface HeadingStyle {
  fontSize?: number;
  bold?: boolean;
}

export interface MentionStyleProperties {
  color?: ColorValue;
  backgroundColor?: ColorValue;
  textDecorationLine?: 'underline' | 'none';
}

export interface HtmlStyle {
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
  ulCheckbox?: {
    boxSize?: number;
    gapWidth?: number;
    marginLeft?: number;
    boxColor?: ColorValue;
  };
}

// Event types

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
}

export interface OnLinkDetected {
  text: string;
  url: string;
  start: number;
  end: number;
}

export interface OnMentionDetected {
  text: string;
  indicator: string;
  attributes: Record<string, string>;
}

export interface OnChangeSelectionEvent {
  start: number;
  end: number;
  text: string;
}

export interface OnKeyPressEvent {
  key: string;
}

export interface OnPasteImagesEvent {
  images: {
    uri: string;
    type: string;
    width: number;
    height: number;
  }[];
}

export interface OnSubmitEditing {
  text: string;
}

// Component types

export type FocusEvent = NativeSyntheticEvent<TargetedEvent>;
export type BlurEvent = NativeSyntheticEvent<TargetedEvent>;

export interface EnrichedTextInputInstance extends NativeMethods {
  // General commands
  focus: () => void;
  blur: () => void;
  setValue: (value: string) => void;
  setSelection: (start: number, end: number) => void;
  getHTML: () => Promise<string>;

  // Text formatting commands
  toggleBold: () => void;
  toggleItalic: () => void;
  toggleUnderline: () => void;
  toggleStrikeThrough: () => void;
  toggleInlineCode: () => void;
  toggleH1: () => void;
  toggleH2: () => void;
  toggleH3: () => void;
  toggleH4: () => void;
  toggleH5: () => void;
  toggleH6: () => void;
  toggleCodeBlock: () => void;
  toggleBlockQuote: () => void;
  toggleOrderedList: () => void;
  toggleUnorderedList: () => void;
  toggleCheckboxList: (checked: boolean) => void;
  setLink: (start: number, end: number, text: string, url: string) => void;
  removeLink: (start: number, end: number) => void;
  setImage: (src: string, width: number, height: number) => void;
  startMention: (indicator: string) => void;
  setMention: (
    indicator: string,
    text: string,
    attributes?: Record<string, string>
  ) => void;
}

export interface ContextMenuItem {
  text: string;
  onPress: ({
    text,
    selection,
    styleState,
  }: {
    text: string;
    selection: { start: number; end: number };
    styleState: OnChangeStateEvent;
  }) => void;
  visible?: boolean;
}

export interface OnChangeMentionEvent {
  indicator: string;
  text: string;
}

export interface EnrichedTextInputProps extends Omit<ViewProps, 'children'> {
  ref?: RefObject<EnrichedTextInputInstance | null>;
  autoFocus?: boolean;
  editable?: boolean;
  mentionIndicators?: string[];
  defaultValue?: string;
  placeholder?: string;
  placeholderTextColor?: ColorValue;
  cursorColor?: ColorValue;
  selectionColor?: ColorValue;
  autoCapitalize?: 'none' | 'sentences' | 'words' | 'characters';
  htmlStyle?: HtmlStyle;
  style?: ViewStyle | TextStyle;
  scrollEnabled?: boolean;
  linkRegex?: RegExp | null;
  returnKeyType?: ReturnKeyTypeOptions;
  returnKeyLabel?: string;
  submitBehavior?: 'submit' | 'blurAndSubmit' | 'newline';
  onFocus?: (e: FocusEvent) => void;
  onBlur?: (e: BlurEvent) => void;
  onChangeText?: (e: NativeSyntheticEvent<OnChangeTextEvent>) => void;
  onChangeHtml?: (e: NativeSyntheticEvent<OnChangeHtmlEvent>) => void;
  onChangeState?: (e: NativeSyntheticEvent<OnChangeStateEvent>) => void;
  onLinkDetected?: (e: OnLinkDetected) => void;
  onMentionDetected?: (e: OnMentionDetected) => void;
  onStartMention?: (indicator: string) => void;
  onChangeMention?: (e: OnChangeMentionEvent) => void;
  onEndMention?: (indicator: string) => void;
  onChangeSelection?: (e: NativeSyntheticEvent<OnChangeSelectionEvent>) => void;
  onKeyPress?: (e: NativeSyntheticEvent<OnKeyPressEvent>) => void;
  onSubmitEditing?: (e: NativeSyntheticEvent<OnSubmitEditing>) => void;
  onPasteImages?: (e: NativeSyntheticEvent<OnPasteImagesEvent>) => void;
  contextMenuItems?: ContextMenuItem[];
  /**
   * If true, Android will use experimental synchronous events.
   * This will prevent from input flickering when updating component size.
   * However, this is an experimental feature, which has not been thoroughly tested.
   * We may decide to enable it by default in a future release.
   * Disabled by default.
   */
  androidExperimentalSynchronousEvents?: boolean;
  /**
   * If true, external HTML (e.g. from Google Docs, Word, web pages) will be
   * normalized through the HTML normalizer before being applied.
   * This converts arbitrary HTML into the canonical tag subset that the enriched
   * parser understands.
   * Disabled by default.
   */
  useHtmlNormalizer?: boolean;
}

// Web-only for now. Native will eventually migrate to EnrichedInputStyle too,
// at which point this interface will be removed and EnrichedTextInputProps
// will use EnrichedInputStyle directly.
export interface EnrichedTextInputWebProps
  extends Omit<EnrichedTextInputProps, 'style'> {
  style?: EnrichedInputStyle;
}

interface EnrichedTextMentionStyleProperties extends MentionStyleProperties {
  pressColor?: ColorValue;
  pressBackgroundColor?: ColorValue;
}

export interface EnrichedTextHtmlStyle
  extends Omit<HtmlStyle, 'a' | 'mention'> {
  a?: HtmlStyle['a'] & {
    pressColor?: ColorValue;
  };
  mention?:
    | Record<string, EnrichedTextMentionStyleProperties>
    | EnrichedTextMentionStyleProperties;
}
