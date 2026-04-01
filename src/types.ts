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
} from 'react-native';

// ─── EnrichedInputStyle ────────────────────────────────────────────────────────
// A flat, hand-written subset of TextStyle (which already extends ViewStyle).
// Use TextStyle['prop'] for complex types to stay in sync with React Native.

export interface EnrichedInputStyle {
  // Layout / FlexStyle
  alignContent?: TextStyle['alignContent'];
  alignItems?: TextStyle['alignItems'];
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
  boxSizing?: 'border-box' | 'content-box';
  columnGap?: number | string;
  direction?: 'inherit' | 'ltr' | 'rtl';
  display?: 'none' | 'flex' | 'contents';
  end?: DimensionValue;
  flex?: number;
  flexBasis?: DimensionValue;
  flexDirection?: 'row' | 'column' | 'row-reverse' | 'column-reverse';
  flexGrow?: number;
  flexShrink?: number;
  flexWrap?: 'wrap' | 'nowrap' | 'wrap-reverse';
  gap?: number | string;
  height?: DimensionValue;
  inset?: DimensionValue;
  insetBlock?: DimensionValue;
  insetBlockEnd?: DimensionValue;
  insetBlockStart?: DimensionValue;
  insetInline?: DimensionValue;
  insetInlineEnd?: DimensionValue;
  insetInlineStart?: DimensionValue;
  justifyContent?: TextStyle['justifyContent'];
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
  overflow?: 'visible' | 'hidden' | 'scroll';
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
  position?: 'absolute' | 'relative' | 'static';
  right?: DimensionValue;
  rowGap?: number | string;
  start?: DimensionValue;
  top?: DimensionValue;
  width?: DimensionValue;
  zIndex?: number;

  // Shadows (iOS)
  shadowColor?: ColorValue;
  shadowOffset?: TextStyle['shadowOffset'];
  shadowOpacity?: TextStyle['shadowOpacity'];
  shadowRadius?: number;

  // Transforms
  transform?: TextStyle['transform'];
  transformOrigin?: TextStyle['transformOrigin'];
  /** @deprecated Use matrix in transform prop instead */
  transformMatrix?: Array<number>;
  /** @deprecated Use rotate in transform prop instead */
  rotation?: TextStyle['rotation'];
  /** @deprecated Use scaleX in transform prop instead */
  scaleX?: TextStyle['scaleX'];
  /** @deprecated Use scaleY in transform prop instead */
  scaleY?: TextStyle['scaleY'];
  /** @deprecated Use translateX in transform prop instead */
  translateX?: TextStyle['translateX'];
  /** @deprecated Use translateY in transform prop instead */
  translateY?: TextStyle['translateY'];

  // View appearance
  backfaceVisibility?: 'visible' | 'hidden';
  backgroundColor?: ColorValue;
  borderBlockColor?: ColorValue;
  borderBlockEndColor?: ColorValue;
  borderBlockStartColor?: ColorValue;
  borderBottomColor?: ColorValue;
  borderBottomEndRadius?: TextStyle['borderBottomEndRadius'];
  borderBottomLeftRadius?: TextStyle['borderBottomLeftRadius'];
  borderBottomRightRadius?: TextStyle['borderBottomRightRadius'];
  borderBottomStartRadius?: TextStyle['borderBottomStartRadius'];
  borderColor?: ColorValue;
  /** @platform ios */
  borderCurve?: 'circular' | 'continuous';
  borderEndColor?: ColorValue;
  borderEndEndRadius?: TextStyle['borderEndEndRadius'];
  borderEndStartRadius?: TextStyle['borderEndStartRadius'];
  borderLeftColor?: ColorValue;
  borderRadius?: TextStyle['borderRadius'];
  borderRightColor?: ColorValue;
  borderStartColor?: ColorValue;
  borderStartEndRadius?: TextStyle['borderStartEndRadius'];
  borderStartStartRadius?: TextStyle['borderStartStartRadius'];
  borderStyle?: 'solid' | 'dotted' | 'dashed';
  borderTopColor?: ColorValue;
  borderTopEndRadius?: TextStyle['borderTopEndRadius'];
  borderTopLeftRadius?: TextStyle['borderTopLeftRadius'];
  borderTopRightRadius?: TextStyle['borderTopRightRadius'];
  borderTopStartRadius?: TextStyle['borderTopStartRadius'];
  boxShadow?: TextStyle['boxShadow'];
  cursor?: TextStyle['cursor'];
  /** @platform android */
  elevation?: number;
  experimental_backgroundImage?: TextStyle['experimental_backgroundImage'];
  filter?: TextStyle['filter'];
  isolation?: 'auto' | 'isolate';
  mixBlendMode?: TextStyle['mixBlendMode'];
  opacity?: TextStyle['opacity'];
  outlineColor?: ColorValue;
  outlineOffset?: TextStyle['outlineOffset'];
  outlineStyle?: 'solid' | 'dotted' | 'dashed';
  outlineWidth?: TextStyle['outlineWidth'];
  pointerEvents?: 'box-none' | 'none' | 'box-only' | 'auto';

  // Typography
  color?: ColorValue;
  fontFamily?: string;
  fontSize?: number;
  fontStyle?: 'normal' | 'italic';
  fontWeight?: TextStyle['fontWeight'];
  letterSpacing?: number;
  lineHeight?: number;
  textAlign?: 'auto' | 'left' | 'right' | 'center' | 'justify';
  textDecorationColor?: ColorValue;
  textDecorationLine?:
    | 'none'
    | 'underline'
    | 'line-through'
    | 'underline line-through';
  textDecorationStyle?: 'solid' | 'double' | 'dotted' | 'dashed';
  textShadowColor?: ColorValue;
  textShadowOffset?: TextStyle['textShadowOffset'];
  textShadowRadius?: number;
  textTransform?: 'none' | 'capitalize' | 'uppercase' | 'lowercase';
  userSelect?: 'auto' | 'none' | 'text' | 'contain' | 'all';

  // iOS-only text
  /** @platform ios */
  fontVariant?: TextStyle['fontVariant'];
  /** @platform ios */
  writingDirection?: 'auto' | 'ltr' | 'rtl';

  // Android-only text
  /** @platform android */
  includeFontPadding?: boolean;
  /** @platform android */
  textAlignVertical?: 'auto' | 'top' | 'bottom' | 'center';
  /** @platform android */
  verticalAlign?: 'auto' | 'top' | 'bottom' | 'middle';
}

// Compile-time compatibility checks — exported so TypeScript doesn't report them as unused.
// Each tuple element evaluates to `true` when the interface is in sync with TextStyle,
// and to `never` (causing a compile error) when it drifts.
//   [0] Fails if EnrichedInputStyle contains a key that doesn't exist in TextStyle.
//   [1] Fails if a TextStyle value is no longer assignable to EnrichedInputStyle.
export type _EnrichedInputStyleCompatChecks = [
  Exclude<keyof EnrichedInputStyle, keyof TextStyle> extends never
    ? true
    : never,
  TextStyle extends EnrichedInputStyle ? true : never,
];

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
  style?: EnrichedInputStyle;
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
