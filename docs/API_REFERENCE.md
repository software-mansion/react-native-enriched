# API Reference

## Props

### `autoFocus`

If `true`, focuses the input.

| Type   | Default Value | Platform |
|--------|---------------|----------|
| `bool` | `false`       | Both     |

### `autoCapitalize`

Tells input to automatically capitalize certain characters.

- `characters`: all characters.
- `words`: first letter of each word.
- `sentences`: first letter of each sentence.
- `none`: don't auto capitalize anything.

| Type                                               | Default Value | Platform |
|----------------------------------------------------|---------------|----------|
| `'none' \| 'sentences' \| 'words' \| 'characters'` | `'sentences'` | Both     |

### `cursorColor`

When provided it will set the color of the cursor (or "caret") in the component.

| Type                                           | Default Value  | Platform |
|------------------------------------------------|----------------|----------|
| [`color`](https://reactnative.dev/docs/colors) | system default | Android  |

### `defaultValue`

Provides an initial value for the input. If the string is a valid HTML output of the `EnrichedTextInput` component (or other HTML that the parser will accept), proper styles will be applied.

| Type     | Default Value | Platform |
|----------|---------------|----------|
| `string` | -             | Both     |

### `editable`

If `false`, text is not editable.

| Type   | Default Value | Platform |
|--------|---------------|----------|
| `bool` | `true`        | Both     |

### `htmlStyle`

A prop for customizing styles appearances.

| Type                           | Default Value                                      | Platform |
|--------------------------------|----------------------------------------------------|----------|
| [`HtmlStyle`](#htmlstyle-type) | default values from [`HtmlStyle`](#htmlstyle-type) | Both     |

### `mentionIndicators`

The recognized mention indicators. Each item needs to be a 1 character long string.

| Type              | Default Value | Platform |
|-------------------|---------------|----------|
| array of `string` | `['@']`       | Both     |

### `onBlur`

Callback that's called whenever the input loses focused (is blurred).

| Type         | Default Value | Platform |
|--------------|---------------|----------|
| `() => void` | -             | Both     |

### `onChangeHtml`

Callback that is called when input's HTML changes.

Payload interface:

```ts
interface OnChangeHtmlEvent {
  value: string;
}
```

- `value` is the new HTML.

| Type                                                       | Default Value | Platform |
|------------------------------------------------------------|---------------|----------|
| `(event: NativeSyntheticEvent<OnChangeHtmlEvent>) => void` | -             | Both     |

### `onChangeMention`

Callback that gets called anytime user makes some changes to a mention that is being edited.

Payload interface:

```ts
interface OnChangeMentionEvent {
  indicator: string;
  text: string;
}
```

- `indicator` is the indicator of the currently edited mention.
- `text` contains whole text that has been typed after the indicator.

| Type                                    | Default Value | Platform |
|-----------------------------------------|---------------|----------|
| `(event: OnChangeMentionEvent) => void` | -             | Both     |

### `onChangeSelection`

Callback that is called each time user changes selection or moves the cursor in the input.

Payload interface:

```ts
interface OnChangeSelectionEvent {
  start: Int32;
  end: Int32;
  text: string;
}
```

- `start` is the index of the selection's beginning.
- `end` is the first index after the selection's ending. For just a cursor in place (no selection), `start` equals `end`.
- `text` is the input's text in the current selection.

| Type                                                            | Default Value | Platform |
|-----------------------------------------------------------------|---------------|----------|
| `(event: NativeSyntheticEvent<OnChangeSelectionEvent>) => void` | -             | Both     |

### `onChangeState`

Callback that gets called when any of the styles within the selection changes.

Payload has a bool flag for each style:

```ts
interface OnChangeStateEvent {
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
```

| Type                                                        | Default Value | Platform |
|-------------------------------------------------------------|---------------|----------|
| `(event: NativeSyntheticEvent<OnChangeStateEvent>) => void` | -             | Both     |

### `onChangeText`

Callback called when any text changes occur in the input.

Payload interface:

```ts
interface OnChangeTextEvent {
  value: string;
}
```

- `value` is the new text value of the input.

| Type                                                       | Default Value | Platform |
|------------------------------------------------------------|---------------|----------|
| `(event: NativeSyntheticEvent<OnChangeTextEvent>) => void` | -             | Both     |

### `onEndMention`

Callback that is called when the user no longer edits a mention actively - has moved the cursor somewhere else or put a space and the cursor isn't within the edited mention.

- `indicator` is the indicator of the mention that was being edited.

| Type                          | Default Value | Platform |
|-------------------------------|---------------|----------|
| `(indicator: string) => void` | -             | Both     |

### `onFocus`

Callback that's called whenever the input is focused.

| Type         | Default Value | Platform |
|--------------|---------------|----------|
| `() => void` | -             | Both     |

### `onLinkDetected`

Callback that gets called when either a new link has been added or the user has moved the cursor/selection to some link.

Payload interface contains all the useful link data:

```ts
interface OnLinkDetected {
  text: string;
  url: string;
  start: Int32;
  end: Int32;
}
```

- `text` is the link's displayed text.
- `url` is the underlying link's URL.
- `start` is the starting index of the link.
- `end` is the first index after the ending index of the link.

| Type                              | Default Value | Platform |
|-----------------------------------|---------------|----------|
| `(event: OnLinkDetected) => void` | -             | Both     |

### `onMentionDetected`

Callback called when mention has been detected - either a new mention has been added or the user has moved the cursor/selection to some mention.

Payload interface contains all the useful mention data:

```ts
interface OnMentionDetected {
  text: string;
  indicator: string;
  attributes: Record<string, string>;
}
```

- `text` is the mention's displayed text.
- `indicator` is the indicator of the mention.
- `attributes` are the additional user-defined attributes that are being stored with the mention.

| Type                                 | Default Value | Platform |
|--------------------------------------|---------------|----------|
| `(event: OnMentionDetected) => void` | -             | Both     |

### `onStartMention`

Callback that gets called whenever a mention editing starts (after placing the indicator).

- `indicator` is the indicator of the mention that begins editing.

| Type                          | Default Value | Platform |
|-------------------------------|---------------|----------|
| `(indicator: string) => void` | -             | Both     |

### `placeholder`

The placeholder text that is displayed in the input if nothing has been typed yet. Disappears when something is typed.

| Type     | Default Value | Platform |
|----------|---------------|----------|
| `string` | `''`          | Both     |

### `placeholderTextColor`

Input placeholder's text color.

| Type                                           | Default Value           | Platform |
|------------------------------------------------|-------------------------|----------|
| [`color`](https://reactnative.dev/docs/colors) | input's [color](#style) | Both     |

### `ref`

A React ref that lets you call any ref methods on the input.

| Type                                           | Default Value | Platform |
|------------------------------------------------|---------------|----------|
| `RefObject<EnrichedTextInputInstance \| null>` | -             | Both     |

### `selectionColor`

Color of the selection rectangle that gets drawn over the selected text. On iOS, the cursor (caret) also gets set to this color.

| Type                                           | Default Value  | Platform |
|------------------------------------------------|----------------|----------|
| [`color`](https://reactnative.dev/docs/colors) | system default | Both     |

### `style`

Accepts most [ViewStyle](https://reactnative.dev/docs/view#style) props, but keep in mind that some of them might not be supported.

Additionally following [TextStyle](https://reactnative.dev/docs/text#style) props are supported

- color
- fontFamily
- fontSize
- fontWeight
- fontStyle only on Android

| Type                                                                                                               | Default Value | Platform |
|--------------------------------------------------------------------------------------------------------------------|---------------|----------|
| [`View Style`](https://reactnative.dev/docs/view#style) \| [`Text Style`](https://reactnative.dev/docs/text#style) | -             | Both     |

### `ViewProps`

The input inherits [ViewProps](https://reactnative.dev/docs/view#props), but keep in mind that some of the props may not be supported.

### `androidExperimentalSynchronousEvents` - EXPERIMENTAL

If true, Android will use experimental synchronous events. This will prevent from input flickering when updating component size. However, this is an experimental feature, which has not been thoroughly tested. We may decide to enable it by default in a future release.

| Type   | Default Value | Platform |
|--------|---------------|----------|
| `bool` | `false`       | Android  |

## Ref Methods

All the methods should be called on the input's [ref](#ref).

### `.blur()`

```ts
blur: () => void;
```

Blurs the input.

### `.focus()`

```ts
focus: () => void;
```

Focuses the input.

### `.setImage()`

```ts
setImage: (src: string, width: number, height: number) => void;
```

Sets the [inline image](../README.md#inline-images) at the current selection.

- `src: string` - absolute path to a file or remote image address.
- `width: number` - width of the image.
- `height: number` - height of the image.

> [!NOTE]
> It's developer responsibility to provide proper width and height, which may require calculating aspect ratio.
> Also, keep in mind that in case of providing incorrect image source, static placeholder will be displayed.
> We may consider adding automatic image size detection and improved error handling in future releases.

### `.setLink()`

```ts
setLink: (
  start: number,
  end: number,
  text: string,
  url: string
) => void;
```

Sets the link at the given place with a given displayed text and URL. Link will replace any text if there was some between `start` and `end` indexes. Setting a link with `start` equal to `end` will just insert it in place.

- `start: number` - the starting index where the link should be.
- `end: number` - first index behind the new link's ending index.
- `text: string` - displayed text of the link.
- `url: string` - URL of the link.

### `.setMention()`

```ts
setMention: (
  indicator: string,
  text: string,
  attributes?: Record<string, string>
) => void;
```

Sets the currently edited mention with a given indicator, displayed text and custom attributes.

- `indicator: string` - the indicator of the set mention.
- `text: string` - the text that should be displayed for the mention. Anything the user typed gets replaced by that text. The mention indicator isn't added to that text.
- `attributes?: Record<string, string>` - additional, custom attributes for the mention that can be passed as a typescript record. They are properly preserved through parsing from and to the HTML format.

### `.setValue()`

```ts
setValue: (value: string) => void;
```

Sets the input's value.

- `value: string` - value to set, it can either be `react-native-enriched` supported HTML string or raw text.

### `.startMention()`

```ts
startMention: (indicator: string) => void;
```

Starts a mention with the given indicator. It gets put at the cursor/selection.

- `indicator: string` - the indicator that starts the new mention.

### `.toggleBlockQuote()`

```ts
toggleBlockQuote: () => void;
```

Toggles blockquote style at the current selection.

### `.toggleBold()`

```ts
toggleBold: () => void;
```

Toggles bold formatting at the current selection.

### `.toggleCodeBlock()`

```ts
toggleCodeBlock: () => void;
```

Toggles codeblock formatting at the current selection.

### `.toggleH1()`

```ts
toggleH1: () => void;
```

Toggles heading 1 (h1) style at the current selection.

### `.toggleH2()`

```ts
toggleH2: () => void;
```

Toggles heading 2 (h2) style at the current selection.

### `.toggleH3()`

```ts
toggleH3: () => void;
```

Toggles heading 3 (h3) style at the current selection.

### `.toggleInlineCode()`

```ts
toggleInlineCode: () => void;
```

Applies inline code formatting to the current selection.

### `.toggleItalic()`

```ts
toggleItalic: () => void;
```

Toggles italic formatting at the current selection.

### `.toggleOrderedList()`

```ts
toggleOrderedList: () => void;
```

Converts current selection into an ordered list.

### `.toggleStrikeThrough()`

```ts
toggleStrikeThrough: () => void;
```

Applies strikethrough formatting to the current selection.

### `.toggleUnderline()`

```ts
toggleUnderline: () => void;
```

Applies underline formatting to the current selection.

### `.toggleUnorderedList()`

```ts
toggleUnorderedList: () => void;
```

Converts current selection into an unordered list.

## HtmlStyle type

Allows customizing HTML styles.

```ts
interface HtmlStyle {
  h1?: {
    fontSize?: number;
    bold?: boolean;
  };
  h2?: {
    fontSize?: number;
    bold?: boolean;
  };
  h3?: {
    fontSize?: number;
    bold?: boolean;
  };
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
}

interface MentionStyleProperties {
  color?: ColorValue;
  backgroundColor?: ColorValue;
  textDecorationLine?: 'underline' | 'none';
}
```

### h1/h2/h3 (headings)

- `fontSize` is the size of the heading's font, defaults to `32`/`24`/`20` for h1/h2/h3.
- `bold` defines whether the heading should be bolded, defaults to `false`.

> [!NOTE]
> On iOS, the headings cannot have same `fontSize` as the component's `fontSize`. Doing so results in unexpected behavior.

### blockquote

- `borderColor` defines the color of the rectangular border drawn to the left of blockquote text. Takes [color](https://reactnative.dev/docs/colors) value, defaults to `darkgray`.
- `borderWidth` sets the width of the said border, defaults to `4`.
- `gapWidth` sets the width of the gap between the border and the blockquote text, defaults to `16`.
- `color` defines the color of blockquote's text. Takes [color](https://reactnative.dev/docs/colors) value, if not set makes the blockquote text the same color as the input's [color prop](#style).

### codeblock

- `color` defines the color of codeblock text, takes [color](https://reactnative.dev/docs/colors) value and defaults to `black`.
- `borderRadius` sets the radius of codeblock's border, defaults to 8.
- `backgroundColor` is the codeblock's background color, takes [color](https://reactnative.dev/docs/colors) value and defaults to `darkgray`.

### code (inline code)

- `color` defines the color of inline code's text, takes [color](https://reactnative.dev/docs/colors) value and defaults to `red`.
- `backgroundColor` is the inline code's background color, takes [color](https://reactnative.dev/docs/colors) value and defaults to `darkgray`.

### a (link)

- `color` defines the color of link's text, takes [color](https://reactnative.dev/docs/colors) value and defaults to `blue`.
- `textDecorationLine` decides if the links are underlined or not, takes either `underline` or `none` and defaults to `underline`

### mention

If only a single config is given, the style applies to all mention types. You can also set a different config for each mentionIndicator that has been defined, then the prop should be a record with indicators as a keys and configs as their values.

- `color` defines the color of mention's text, takes [color](https://reactnative.dev/docs/colors) value and defaults to `blue`.
- `backgroundColor` is the mention's background color, takes [color](https://reactnative.dev/docs/colors) value and defaults to `yellow`.
- `textDecorationLine` decides if the mentions are underlined or not, takes either `underline` or `none` and defaults to `underline`.

### ol (ordered list)

By marker we mean the number that denotes next lines of the list.

- `gapWidth` sets the gap between the marker and the list item's text, defaults to `16`.
- `marginLeft` sets the margin to the left of the marker (between the marker and input's left edge), defaults to `16`.
- `markerFontWeight` defines the font weight of the marker, takes a [fontWeight](https://reactnative.dev/docs/text-style-props#fontweight) value and if not set, defaults to the same font weight as input's [fontWeight prop](#style).
- `markerColor` sets the text color of the marker, takes [color](https://reactnative.dev/docs/colors) value and if not set, defaults to the same color as input's [color prop](#style).

### ul (unordered list)

By bullet we mean the dot that begins each line of the list.

- `bulletColor` defines the color of the bullet, takes [color](https://reactnative.dev/docs/colors) value and defaults to `black`.
- `bulletSize` sets both the height and the width of the bullet, defaults to `8`.
- `marginLeft` is the margin to the left of the bullet (between the bullet and input's left edge), defaults to `16`.
- `gapWidth` sets the gap between the bullet and the list item's text, defaults to `16`.
