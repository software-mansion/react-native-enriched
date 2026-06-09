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

/**
 * Allowed container styles for `<EnrichedTextInput />`'s `style` prop.
 *
 * Represents the supported subset of React Native
 * [`TextStyle`](https://reactnative.dev/docs/text-style-props).
 * Some properties are not supported on all platforms. In such cases a property
 * is annotated with a `@platform` directive.
 */
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
  alignment: string;
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

/**
 * Imperative handle exposed via `ref` on `<EnrichedTextInput />`.
 *
 * Obtain a reference with `useRef<EnrichedTextInputInstance>(null)` and pass it
 * to the component's `ref` prop. All methods are safe to call after the
 * component has mounted.
 */
export interface EnrichedTextInputInstance extends NativeMethods {
  /** Focuses the editor, opening the software keyboard on mobile. */
  focus: () => void;

  /** Removes focus from the editor and dismisses the software keyboard. */
  blur: () => void;

  /** Replaces the entire editor content with the supplied html/plain-text`value`. */
  setValue: (value: string) => void;

  /** Moves the text cursor (or extends the selection) to the range `[start, end]`. */
  setSelection: (start: number, end: number) => void;

  /**
   * Returns the current editor content as an HTML string.
   * The promise resolves once the native layer has completed HTML parsing.
   */
  getHTML: () => Promise<string>;

  /** Toggles bold on the current selection (or toggles it for future typing if nothing is selected). */
  toggleBold: () => void;

  /** Toggles italic on the current selection (or toggles it for future typing if nothing is selected). */
  toggleItalic: () => void;

  /** Toggles underline on the current selection (or toggles it for future typing if nothing is selected). */
  toggleUnderline: () => void;

  /** Toggles strikethrough on the current selection (or toggles it for future typing if nothing is selected). */
  toggleStrikeThrough: () => void;

  /** Toggles inline code on the current selection (or toggles it for future typing if nothing is selected). */
  toggleInlineCode: () => void;

  /** Toggles an H1 heading on the current selection or the focused paragraph. */
  toggleH1: () => void;

  /** Toggles an H2 heading on the current selection or the focused paragraph. */
  toggleH2: () => void;

  /** Toggles an H3 heading on the current selection or the focused paragraph. */
  toggleH3: () => void;

  /** Toggles an H4 heading on the current selection or the focused paragraph. */
  toggleH4: () => void;

  /** Toggles an H5 heading on the current selection or the focused paragraph. */
  toggleH5: () => void;

  /** Toggles an H6 heading on the current selection or the focused paragraph. */
  toggleH6: () => void;

  /** Toggles a code block on the current selection or the focused paragraph. */
  toggleCodeBlock: () => void;

  /** Toggles a block-quote on the current selection or the focused paragraph. */
  toggleBlockQuote: () => void;

  /**
   * Toggles an ordered (numbered) list on the current selection or the
   * focused paragraph.
   */
  toggleOrderedList: () => void;

  /**
   * Toggles an unordered (bullet) list on the current selection or the
   * focused paragraph.
   */
  toggleUnorderedList: () => void;

  /**
   * Toggles a checkbox (task) list on the current selection or the focused
   * paragraph. Pass `checked` as `true` to pre-check the inserted items.
   */
  toggleCheckboxList: (checked: boolean) => void;

  /**
   * Inserts or updates a hyperlink over the character range `[start, end]`.
   *
   * @param start - Start offset of the linked text (inclusive).
   * @param end   - End offset of the linked text (exclusive).
   * @param text  - Display text for the link.
   * @param url   - URL the link should navigate to.
   */
  setLink: (start: number, end: number, text: string, url: string) => void;

  /**
   * Removes any hyperlink from the `[start, end]` range while
   * preserving the underlying text.
   *
   * @param start - Start offset (inclusive).
   * @param end   - End offset (exclusive).
   */
  removeLink: (start: number, end: number) => void;

  /**
   * Inserts an image at the current cursor position.
   *
   * @param src    - URI of the image (remote URL or local asset path).
   * @param width  - Width of the image.
   * @param height - Height of the image.
   */
  setImage: (src: string, width: number, height: number) => void;

  /**
   * Opens a mention flow by inserting the given `indicator` character (e.g.
   * `"@"` or `"#"`) at the current cursor position and firing
   * `onStartMention`.
   */
  startMention: (indicator: string) => void;

  /**
   * Finalizes an in-progress mention by replacing the typed text with a
   * specified mention value.
   *
   * @param indicator  - The trigger character (e.g. `"@"`).
   * @param text       - Display text for the mention (e.g. the user's name).
   * @param attributes - Optional key/value pairs attached to the mention tag (e.g. `{ id: "42" }`).
   */
  setMention: (
    indicator: string,
    text: string,
    attributes?: Record<string, string>
  ) => void;

  /**
   * Sets the horizontal text alignment for the paragraph(s) at the current
   * selection.
   *
   * @param alignment - One of `"left"`, `"center"`, `"right"`, `"justify"`, or `"auto"`.
   */
  setTextAlignment: (
    alignment: 'left' | 'center' | 'right' | 'justify' | 'auto'
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

/**
 * Props for the `<EnrichedTextInput />` rich-text editor component.
 */
export interface EnrichedTextInputProps extends Omit<ViewProps, 'children'> {
  /**
   * Ref to the imperative handle that exposes editor commands.
   * Create with `useRef<EnrichedTextInputInstance>(null)`.
   */
  ref?: RefObject<EnrichedTextInputInstance | null>;

  /** If `true`, the editor is focused automatically when it mounts. */
  autoFocus?: boolean;

  /**
   * If `false`, the editor becomes read-only and the keyboard will not appear.
   * Defaults to `true`.
   */
  editable?: boolean;

  /**
   * List of single-character strings that trigger the mention flow (e.g.
   * `["@", "#"]`). When the user types one of these characters the
   * `onStartMention` callback is fired.
   */
  mentionIndicators?: string[];

  /**
   * Initial content rendered when the component mounts. Changes to this prop
   * after mount are **ignored** — use `ref.setValue()` to update the content
   * imperatively.
   */
  defaultValue?: string;

  /** Placeholder text shown when the editor is empty. */
  placeholder?: string;

  /** Color of the placeholder text. */
  placeholderTextColor?: ColorValue;

  /** Color of the cursor. */
  cursorColor?: ColorValue;

  /** Highlight color for selected text. */
  selectionColor?: ColorValue;

  /** Controls automatic capitalization of typed text. Defaults to `"sentences"`. */
  autoCapitalize?: 'none' | 'sentences' | 'words' | 'characters';

  /** Style overrides applied to the rendered HTML content inside the editor. */
  htmlStyle?: HtmlStyle;

  /** Style applied to the outer container view of the editor. */
  style?: EnrichedInputStyle;

  /**
   * If `false`, the editor's internal scroll view is disabled and the component
   * expands to fit all content. Defaults to `true`.
   */
  scrollEnabled?: boolean;

  /**
   * Regular expression used to auto-detect links as the user types. Set to
   * `null` to disable automatic link detection. Defaults to a built-in URL
   * pattern.
   */
  linkRegex?: RegExp | null;

  /** The label shown on the return key of the software keyboard. */
  returnKeyType?: ReturnKeyTypeOptions;

  /** Custom text label for the return key (Android only). */
  returnKeyLabel?: string;

  /**
   * Controls what happens when the user presses the return key.
   * - `"submit"` — fires `onSubmitEditing` without inserting a newline.
   * - `"blurAndSubmit"` — blurs the editor and fires `onSubmitEditing`.
   * - `"newline"` — inserts a newline (default).
   */
  submitBehavior?: 'submit' | 'blurAndSubmit' | 'newline';

  /** Called when the editor receives focus. */
  onFocus?: (e: FocusEvent) => void;

  /** Called when the editor loses focus. */
  onBlur?: (e: BlurEvent) => void;

  /** Called whenever the plain-text content of the editor changes. */
  onChangeText?: (e: NativeSyntheticEvent<OnChangeTextEvent>) => void;

  /**
   * Called whenever the HTML representation of the editor content changes.
   *
   * Note: parsing HTML on every keystroke is expensive and may cause
   * performance issues. Consider calling `ref.getHTML()` on demand (e.g. on
   * submit) instead.
   */
  onChangeHtml?: (e: NativeSyntheticEvent<OnChangeHtmlEvent>) => void;

  /**
   * Called whenever the active formatting state changes (e.g. the cursor
   * moves into a bold region). Use this to update toolbar toggle states.
   */
  onChangeState?: (e: NativeSyntheticEvent<OnChangeStateEvent>) => void;

  /** Called when the editor auto-detects a URL matching `linkRegex`. */
  onLinkDetected?: (e: OnLinkDetected) => void;

  /** Called when the editor resolves a mention node. */
  onMentionDetected?: (e: OnMentionDetected) => void;

  /**
   * Called when a mention trigger character is typed. Use this to show a
   * mention picker UI. `indicator` is the trigger character (e.g. `"@"`).
   */
  onStartMention?: (indicator: string) => void;

  /**
   * Called as the user continues typing after the mention trigger. Use the
   * `text` field to filter the mention picker list.
   */
  onChangeMention?: (e: OnChangeMentionEvent) => void;

  /**
   * Called when the mention flow ends (e.g. the user presses Escape or the
   * cursor leaves the mention token). `indicator` is the trigger character.
   */
  onEndMention?: (indicator: string) => void;

  /** Called when the text selection range changes. */
  onChangeSelection?: (e: NativeSyntheticEvent<OnChangeSelectionEvent>) => void;

  /** Called when a key is pressed while the editor is focused. */
  onKeyPress?: (e: NativeSyntheticEvent<OnKeyPressEvent>) => void;

  /** Called when the user presses the return key and `submitBehavior` triggers a submit. */
  onSubmitEditing?: (e: NativeSyntheticEvent<OnSubmitEditing>) => void;

  /** Called when the user pastes one or more images into the editor. */
  onPasteImages?: (e: NativeSyntheticEvent<OnPasteImagesEvent>) => void;

  /**
   * Additional items to inject into the native text-selection context menu
   * (the popover that appears when the user long-presses selected text).
   */
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

  /**
   * If true, fonts will scale to respect the system's accessibility text size.
   * Enabled by default.
   */
  allowFontScaling?: boolean;
}

/**
 * Imperative handle exposed via `ref` on `<EnrichedText />`.
 *
 * Inherits the full React Native `NativeMethods` surface (`measure`,
 * `measureInWindow`, `measureLayout`, `setNativeProps`, `focus`, `blur`).
 * Obtain a reference with `useRef<EnrichedTextInstance>(null)`.
 */
export interface EnrichedTextInstance extends NativeMethods {}

/**
 * Props for the `<EnrichedText />` read-only rich-text rendering component.
 */
export interface EnrichedTextProps extends ViewProps {
  /**
   * Ref to the imperative handle that exposes native measurement and focus
   * methods inherited from `NativeMethods`.
   * Create with `useRef<EnrichedTextInstance>(null)`.
   */
  ref?: RefObject<EnrichedTextInstance | null>;

  /** HTML/plain-text string to render as rich text. */
  children: string;

  /** Style applied to the container view. */
  style?: TextStyle;

  /** Style overrides applied to the rendered HTML content. */
  htmlStyle?: EnrichedTextHtmlStyle;

  /**
   * If true, external HTML will be normalized through the HTML normalizer
   * before being rendered. Disabled by default.
   */
  useHtmlNormalizer?: boolean;

  /**
   * How to truncate text when it overflows `numberOfLines`.
   * - `"head"` — truncates the beginning.
   * - `"middle"` — truncates the middle.
   * - `"tail"` — truncates the end (default).
   * - `"clip"` — clips at the boundary without an ellipsis.
   */
  ellipsizeMode?: 'head' | 'middle' | 'tail' | 'clip';

  /**
   * Maximum number of lines to display. Text that exceeds this limit is
   * truncated according to `ellipsizeMode`.
   */
  numberOfLines?: number;

  /** If `true`, the rendered text can be selected and copied by the user. */
  selectable?: boolean;

  /** Highlight color for selected text. */
  selectionColor?: ColorValue;

  /**
   * If true, fonts will scale to respect the system's accessibility text size.
   * Enabled by default.
   */
  allowFontScaling?: boolean;

  /** Called when the user taps a hyperlink inside the rendered content. */
  onLinkPress?: (event: OnLinkPressEvent) => void;

  /** Called when the user taps a mention node inside the rendered content. */
  onMentionPress?: (event: OnMentionPressEvent) => void;
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

export interface OnLinkPressEvent {
  url: string;
}

export interface OnMentionPressEvent {
  text: string;
  indicator: string;
  attributes: Record<string, string>;
}
