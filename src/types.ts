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
  alignContent?: TextStyle['alignContent']; // NOT OK
  alignItems?: TextStyle['alignItems']; // NOT OK
  alignSelf?: TextStyle['alignSelf']; // OK
  aspectRatio?: number | string; // OK
  borderBottomWidth?: number; // OK
  borderEndWidth?: number; // OK
  borderLeftWidth?: number; // OK
  borderRightWidth?: number; // OK
  borderStartWidth?: number; // OK
  borderTopWidth?: number; // OK
  borderWidth?: number; // OK
  bottom?: DimensionValue; // OK
  boxSizing?: 'border-box' | 'content-box'; // OK
  columnGap?: number | string; // NOT OK
  direction?: 'inherit' | 'ltr' | 'rtl'; // NOT OK
  display?: 'none' | 'flex' | 'contents'; // OK
  end?: DimensionValue; // OK
  flex?: number; // OK
  flexBasis?: DimensionValue; // OK
  flexDirection?: 'row' | 'column' | 'row-reverse' | 'column-reverse'; // NOT OK
  flexGrow?: number; // OK
  flexShrink?: number; // OK
  flexWrap?: 'wrap' | 'nowrap' | 'wrap-reverse'; // NOT OK
  gap?: number | string; // NOT OK
  height?: DimensionValue; // OK
  inset?: DimensionValue; // OK
  insetBlock?: DimensionValue; // OK
  insetBlockEnd?: DimensionValue; // OK
  insetBlockStart?: DimensionValue; // OK
  insetInline?: DimensionValue; // OK
  insetInlineEnd?: DimensionValue; // OK
  insetInlineStart?: DimensionValue; // OK
  justifyContent?: TextStyle['justifyContent']; // NOT OK
  left?: DimensionValue; // OK
  margin?: DimensionValue; // OK
  marginBlock?: DimensionValue; // OK
  marginBlockEnd?: DimensionValue; // OK
  marginBlockStart?: DimensionValue; // OK
  marginBottom?: DimensionValue; // OK
  marginEnd?: DimensionValue; // OK
  marginHorizontal?: DimensionValue; // OK
  marginInline?: DimensionValue; // OK
  marginInlineEnd?: DimensionValue; // OK
  marginInlineStart?: DimensionValue; // OK
  marginLeft?: DimensionValue; // OK
  marginRight?: DimensionValue; // OK
  marginStart?: DimensionValue; // OK
  marginTop?: DimensionValue; // OK
  marginVertical?: DimensionValue; // OK
  maxHeight?: DimensionValue; // OK
  maxWidth?: DimensionValue; // OK
  minHeight?: DimensionValue; // OK
  minWidth?: DimensionValue; // OK
  overflow?: 'visible' | 'hidden' | 'scroll'; // NOT OK
  padding?: DimensionValue; // OK
  paddingBlock?: DimensionValue; // OK
  paddingBlockEnd?: DimensionValue; // OK
  paddingBlockStart?: DimensionValue; // OK
  paddingBottom?: DimensionValue; // OK
  paddingEnd?: DimensionValue; // OK
  paddingHorizontal?: DimensionValue; // OK
  paddingInline?: DimensionValue; // OK
  paddingInlineEnd?: DimensionValue; // OK
  paddingInlineStart?: DimensionValue; // OK
  paddingLeft?: DimensionValue; // OK
  paddingRight?: DimensionValue; // OK
  paddingStart?: DimensionValue; // OK
  paddingTop?: DimensionValue; // OK
  paddingVertical?: DimensionValue; // OK
  position?: 'absolute' | 'relative' | 'static'; // OK
  right?: DimensionValue; // OK
  rowGap?: number | string; // NOT OK
  start?: DimensionValue; // OK
  top?: DimensionValue; // OK
  width?: DimensionValue; // OK
  zIndex?: number; // OK

  // Shadows (iOS)
  shadowColor?: ColorValue; // OK IOS-ONLY
  shadowOffset?: TextStyle['shadowOffset']; // OK IOS-ONLY
  shadowOpacity?: TextStyle['shadowOpacity']; // OK IOS-ONLY
  shadowRadius?: number; // OK IOS-ONLY

  // Transforms
  transform?: TextStyle['transform']; // OK
  transformOrigin?: TextStyle['transformOrigin']; // OK
  /** @deprecated Use matrix in transform prop instead */
  transformMatrix?: Array<number>; // NOT OK
  /** @deprecated Use rotate in transform prop instead */
  rotation?: TextStyle['rotation']; // NOT OK
  /** @deprecated Use scaleX in transform prop instead */
  scaleX?: TextStyle['scaleX']; // NOT OK
  /** @deprecated Use scaleY in transform prop instead */
  scaleY?: TextStyle['scaleY']; // NOT OK
  /** @deprecated Use translateX in transform prop instead */
  translateX?: TextStyle['translateX']; // NOT OK
  /** @deprecated Use translateY in transform prop instead */
  translateY?: TextStyle['translateY']; // NOT OK

  // View appearance
  backfaceVisibility?: 'visible' | 'hidden'; // OK IOS-ONLY
  backgroundColor?: ColorValue; // OK
  borderBlockColor?: ColorValue; // OK IOS-ONLY
  borderBlockEndColor?: ColorValue; // OK IOS-ONLY
  borderBlockStartColor?: ColorValue; // OK IOS-ONLY
  borderBottomColor?: ColorValue; // OK IOS-ONLY
  borderBottomEndRadius?: TextStyle['borderBottomEndRadius']; // OK IOS-ONLY
  borderBottomLeftRadius?: TextStyle['borderBottomLeftRadius']; // OK IOS-ONLY
  borderBottomRightRadius?: TextStyle['borderBottomRightRadius']; // OK IOS-ONLY
  borderBottomStartRadius?: TextStyle['borderBottomStartRadius']; // OK IOS-ONLY
  borderColor?: ColorValue; // OK IOS-ONLY
  /** @platform ios */
  borderCurve?: 'circular' | 'continuous'; // NOT OK
  borderEndColor?: ColorValue; // OK IOS-ONLY
  borderEndEndRadius?: TextStyle['borderEndEndRadius']; // OK IOS-ONLY
  borderEndStartRadius?: TextStyle['borderEndStartRadius']; // OK IOS-ONLY
  borderLeftColor?: ColorValue; // OK IOS-ONLY
  borderRadius?: TextStyle['borderRadius']; // OK IOS-ONLY
  borderRightColor?: ColorValue; // OK IOS-ONLY
  borderStartColor?: ColorValue; // OK IOS-ONLY
  borderStartEndRadius?: TextStyle['borderStartEndRadius']; // OK IOS-ONLY
  borderStartStartRadius?: TextStyle['borderStartStartRadius']; // OK IOS-ONLY
  borderStyle?: 'solid' | 'dotted' | 'dashed'; // OK IOS-ONLY
  borderTopColor?: ColorValue; // OK IOS-ONLY
  borderTopEndRadius?: TextStyle['borderTopEndRadius']; // OK IOS-ONLY
  borderTopLeftRadius?: TextStyle['borderTopLeftRadius']; // OK IOS-ONLY
  borderTopRightRadius?: TextStyle['borderTopRightRadius']; // OK IOS-ONLY
  borderTopStartRadius?: TextStyle['borderTopStartRadius']; // OK IOS-ONLY
  boxShadow?: TextStyle['boxShadow']; // OK
  cursor?: TextStyle['cursor']; // OK WEB-ONLY

  /** @platform android */
  elevation?: number; // OK ANDROID-ONLY
  experimental_backgroundImage?: TextStyle['experimental_backgroundImage']; // NOT OK
  filter?: TextStyle['filter']; // OK ANDROID-ONLY
  isolation?: 'auto' | 'isolate'; // NOT OK
  mixBlendMode?: TextStyle['mixBlendMode']; // OK ANDROID-ONLY
  opacity?: TextStyle['opacity']; // OK
  outlineColor?: ColorValue; // OK IOS-ONLY
  outlineOffset?: TextStyle['outlineOffset']; // OK
  outlineStyle?: 'solid' | 'dotted' | 'dashed'; // OK ANDROID-ONLY
  outlineWidth?: TextStyle['outlineWidth']; // OK
  pointerEvents?: 'box-none' | 'none' | 'box-only' | 'auto'; // OK IOS-ONLY

  // Typography
  color?: ColorValue; // OK
  fontFamily?: string; // OK
  fontSize?: number; // OK
  fontStyle?: 'normal' | 'italic'; // OK
  fontWeight?: TextStyle['fontWeight']; // OK
  letterSpacing?: number; // NOT OK
  lineHeight?: number; // OK
  textAlign?: 'auto' | 'left' | 'right' | 'center' | 'justify'; // NOT OK
  textDecorationColor?: ColorValue; // NOT OK
  textDecorationLine?:
    | 'none'
    | 'underline'
    | 'line-through'
    | 'underline line-through'; // NOT OK
  textDecorationStyle?: 'solid' | 'double' | 'dotted' | 'dashed'; // NOT OK
  textShadowColor?: ColorValue; // NOT OK
  textShadowOffset?: TextStyle['textShadowOffset']; // NOT OK
  textShadowRadius?: number; // NOT OK
  textTransform?: 'none' | 'capitalize' | 'uppercase' | 'lowercase'; // NOT OK
  userSelect?: 'auto' | 'none' | 'text' | 'contain' | 'all'; // NOT OK

  // iOS-only text
  /** @platform ios */
  fontVariant?: TextStyle['fontVariant']; // NOT OK
  /** @platform ios */
  writingDirection?: 'auto' | 'ltr' | 'rtl'; // NOT OK

  // Android-only text
  /** @platform android */
  includeFontPadding?: boolean; // NOT OK
  /** @platform android */
  textAlignVertical?: 'auto' | 'top' | 'bottom' | 'center'; // NOT OK
  /** @platform android */
  verticalAlign?: 'auto' | 'top' | 'bottom' | 'middle'; // NOT OK
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
