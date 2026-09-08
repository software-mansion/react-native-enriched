---
sidebar_position: 1
---

# EnrichedTextInput

`EnrichedTextInput` is a rich text editor that styles text live as you type.
See [Core concepts](/fundamentals/core-concepts) for the mental model.

## Reference

```tsx
import { useRef } from 'react';
import { EnrichedTextInput } from 'react-native-enriched-html';
import type { EnrichedTextInputInstance } from 'react-native-enriched-html';

function App() {
  const ref = useRef<EnrichedTextInputInstance>(null);

  return (
    <EnrichedTextInput
      ref={ref}
      style={{ fontSize: 18, minHeight: 96 }}
      placeholder="Type something here..."
      onChangeState={e => {
        // e.nativeEvent.bold.isActive, ...
      }}
    />
  );
}
```

<details>
<summary>Type definitions</summary>

```ts
interface EnrichedTextInputProps extends Omit<ViewProps, 'children'> {
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
  sanitizationConfig?: SanitizationConfig;
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
  textShortcuts?: TextShortcut[];
  androidExperimentalSynchronousEvents?: boolean;
  useHtmlNormalizer?: boolean;
  allowFontScaling?: boolean;
}
```

</details>

## Props

All props are optional.

### `allowFontScaling` {#allowfontscaling}

If `true`, the input respects the system's accessibility font scaling settings.

| Type      | Default | Platforms    |
| --------- | ------- | ------------ |
| `boolean` | `true`  | Android, iOS |

### `autoFocus` {#autofocus}

If `true`, focuses the input when it mounts.

| Type      | Default | Platforms         |
| --------- | ------- | ----------------- |
| `boolean` | `false` | Android, iOS, Web |

### `autoCapitalize` {#autocapitalize}

Tells the input to automatically capitalize certain characters.

- `characters` - all characters
- `words` - first letter of each word
- `sentences` - first letter of each sentence
- `none` - don't auto-capitalize anything

| Type                                               | Default       | Platforms         |
| -------------------------------------------------- | ------------- | ----------------- |
| `'none' \| 'sentences' \| 'words' \| 'characters'` | `'sentences'` | Android, iOS, Web |

### `contextMenuItems` {#contextmenuitems}

An array of custom items to display in the native text editing menu. Each item
specifies a title, visibility flag, and a callback that fires when the item is
tapped.

```ts
interface ContextMenuItem {
  text: string;
  onPress: (args: {
    text: string;
    selection: { start: number; end: number };
    styleState: OnChangeStateEvent;
  }) => void;
  visible?: boolean;
}
```

- `text` is the title displayed in the menu
- `onPress` is the callback invoked when the item is tapped
- `visible` controls whether the item is shown; defaults to `true`

The `onPress` callback receives a single object argument with:

- `text` - the currently selected text
- `selection` - an object with `start` and `end` indices of the current selection
- `styleState` - the latest `OnChangeStateEvent` payload reflecting active styles
  at the time of the tap

| Type                | Default | Platforms    |
| ------------------- | ------- | ------------ |
| `ContextMenuItem[]` | -       | Android, iOS |

:::note

On iOS, items appear in array order, before the system items (Copy/Paste/Cut).
On Android, there is no guaranteed order and custom items may be displayed in a
submenu, depending on the device manufacturer.

:::

See [Custom context menu](/guides/custom-context-menu) for a full example.

### `cursorColor` {#cursorcolor}

Sets the color of the cursor (caret) in the component.

| Type                                           | Default        | Platforms    |
| ---------------------------------------------- | -------------- | ------------ |
| [`color`](https://reactnative.dev/docs/colors) | system default | Android, Web |

### `defaultValue` {#defaultvalue}

Provides an initial value for the input. If the string is a valid HTML output of
`EnrichedTextInput` (or other HTML that the parser will accept), proper styles
are applied.

| Type     | Default | Platforms         |
| -------- | ------- | ----------------- |
| `string` | -       | Android, iOS, Web |

### `editable` {#editable}

If `false`, text is not editable.

| Type      | Default | Platforms         |
| --------- | ------- | ----------------- |
| `boolean` | `true`  | Android, iOS, Web |

:::note

Setting `editable` to `false` disables all user interactions with the input.
Some programmatic changes (like toggling styles or changing value imperatively)
via ref methods still work.

:::

### `htmlStyle` {#htmlstyle}

Customizes the appearance of HTML elements inside the editor. See
[`HtmlStyle`](#htmlstyle-type).

| Type        | Default                                            | Platforms         |
| ----------- | -------------------------------------------------- | ----------------- |
| `HtmlStyle` | default values from [`HtmlStyle`](#htmlstyle-type) | Android, iOS, Web |

### `mentionIndicators` {#mentionindicators}

The recognized mention indicators. Each item must be a 1-character string. See
[Mentions](/rich-text-formatting/mentions) for how indicators are used.

| Type       | Default | Platforms         |
| ---------- | ------- | ----------------- |
| `string[]` | `['@']` | Android, iOS, Web |

### `linkRegex` {#linkregex}

A custom regex pattern for detecting links in the input. If not provided, a
default regex is used. You can customize which patterns are recognized as links

- for example only `https://` URLs, or custom schemes.

Not all JS regex features are supported; for example variable-width lookbehinds
won't work.

| Type             | Default                       | Platforms         |
| ---------------- | ----------------------------- | ----------------- |
| `RegExp \| null` | default native platform regex | Android, iOS, Web |

:::tip

Pass `null` to disable link detection completely.

:::

:::caution

Links might get stripped if sanitization is not configured properly.
For details, see [sanitization](/core-functionalities/web-support).

:::

### `onBlur` {#onblur}

Called whenever the input loses focus.

| Type                     | Platforms         |
| ------------------------ | ----------------- |
| `(e: BlurEvent) => void` | Android, iOS, Web |

### `onChangeHtml` {#onchangehtml}

Called when the input's HTML changes.

```ts
interface OnChangeHtmlEvent {
  value: string;
}
```

- `value` is the new HTML

| Type                                                       | Platforms         |
| ---------------------------------------------------------- | ----------------- |
| `(event: NativeSyntheticEvent<OnChangeHtmlEvent>) => void` | Android, iOS, Web |

:::tip

Specifying `onChangeHtml` may have performance implications, especially with
large documents, as it requires continuous HTML parsing. If you only need the
HTML at specific moments (for example when saving), use the
[`getHTML`](#gethtml) ref method instead.

:::

### `onChangeMention` {#onchangemention}

Called whenever the text typed after the mention indicator changes while a mention is being edited.

```ts
interface OnChangeMentionEvent {
  indicator: string;
  text: string;
}
```

- `indicator` is the indicator of the currently edited mention
- `text` contains the whole text typed after the indicator

| Type                                    | Platforms         |
| --------------------------------------- | ----------------- |
| `(event: OnChangeMentionEvent) => void` | Android, iOS, Web |

### `onChangeSelection` {#onchangeselection}

Called each time the user changes the selection or moves the cursor.

```ts
interface OnChangeSelectionEvent {
  start: number;
  end: number;
  text: string;
}
```

- `start` is the index of the selection's beginning
- `end` is the first index after the selection's ending; for a cursor with no
  selection, `start` equals `end`
- `text` is the input's text in the current selection

| Type                                                            | Platforms         |
| --------------------------------------------------------------- | ----------------- |
| `(event: NativeSyntheticEvent<OnChangeSelectionEvent>) => void` | Android, iOS, Web |

### `onChangeState` {#onchangestate}

Called when any of the styles within the selection changes. Use this to drive
toolbar button state. See
[The style state model](/fundamentals/core-concepts#the-style-state-model).

```ts
interface StyleState {
  isActive: boolean;
  isConflicting: boolean;
  isBlocking: boolean;
}

interface OnChangeStateEvent {
  bold: StyleState;
  italic: StyleState;
  underline: StyleState;
  strikeThrough: StyleState;
  inlineCode: StyleState;
  h1: StyleState;
  h2: StyleState;
  h3: StyleState;
  h4: StyleState;
  h5: StyleState;
  h6: StyleState;
  codeBlock: StyleState;
  blockQuote: StyleState;
  orderedList: StyleState;
  unorderedList: StyleState;
  link: StyleState;
  image: StyleState;
  mention: StyleState;
  checkboxList: StyleState;
  alignment: string;
}
```

- `isActive` - the style is active within the current selection
- `isBlocking` - the style is blocked by another currently active style, so it
  can't be toggled
- `isConflicting` - toggling the style removes a conflicting active style
- `alignment` - current text alignment of the paragraph at the cursor:
  `'left'`, `'center'`, `'right'`, `'justify'`, or `'auto'`

:::note

On Android, `'justify'` is not supported. It is accepted in the type signature
but has no justified layout effect - text is shown with natural alignment
instead, the same as `'auto'`.

:::

| Type                                                        | Platforms         |
| ----------------------------------------------------------- | ----------------- |
| `(event: NativeSyntheticEvent<OnChangeStateEvent>) => void` | Android, iOS, Web |

### `onChangeText` {#onchangetext}

Called when any text changes occur in the input.

```ts
interface OnChangeTextEvent {
  value: string;
}
```

- `value` is the new plain-text value of the input

| Type                                                       | Platforms         |
| ---------------------------------------------------------- | ----------------- |
| `(event: NativeSyntheticEvent<OnChangeTextEvent>) => void` | Android, iOS, Web |

### `onEndMention` {#onendmention}

Called when the user is no longer editing a mention actively - they moved the
cursor elsewhere, or typed a space and the cursor is no longer within the edited
mention.

- `indicator` is the indicator of the mention that was being edited

| Type                          | Platforms         |
| ----------------------------- | ----------------- |
| `(indicator: string) => void` | Android, iOS, Web |

### `onFocus` {#onfocus}

Called whenever the input is focused.

| Type                      | Platforms         |
| ------------------------- | ----------------- |
| `(e: FocusEvent) => void` | Android, iOS, Web |

### `onLinkDetected` {#onlinkdetected}

Called when the user has moved the
cursor/selection onto a link.

```ts
interface OnLinkDetected {
  text: string;
  url: string;
  start: number;
  end: number;
}
```

- `text` is the link's displayed text
- `url` is the underlying URL
- `start` is the starting index of the link
- `end` is the first index after the ending index of the link

| Type                              | Platforms         |
| --------------------------------- | ----------------- |
| `(event: OnLinkDetected) => void` | Android, iOS, Web |

### `onMentionDetected` {#onmentiondetected}

Called when the
user moved the cursor/selection onto a mention.

```ts
interface OnMentionDetected {
  text: string;
  indicator: string;
  attributes: Record<string, string>;
}
```

- `text` is the mention's displayed text
- `indicator` is the indicator of the mention
- `attributes` are the additional user-defined attributes stored with the mention

| Type                                 | Platforms         |
| ------------------------------------ | ----------------- |
| `(event: OnMentionDetected) => void` | Android, iOS, Web |

### `onStartMention` {#onstartmention}

Called whenever mention editing starts.

- `indicator` is the indicator of the mention that begins editing

| Type                          | Platforms         |
| ----------------------------- | ----------------- |
| `(indicator: string) => void` | Android, iOS, Web |

### `onKeyPress` {#onkeypress}

Called when a key is pressed. See
[TextInput onKeyPress](https://reactnative.dev/docs/textinput#onkeypress) for
more details.

```ts
interface OnKeyPressEvent {
  key: string;
}
```

| Type                                                     | Platforms         |
| -------------------------------------------------------- | ----------------- |
| `(event: NativeSyntheticEvent<OnKeyPressEvent>) => void` | Android, iOS, Web |

### `onSubmitEditing` {#onsubmitediting}

Called when the user submits the input (presses the return/enter key while
`submitBehavior` is `'submit'` or `'blurAndSubmit'`).

```ts
interface OnSubmitEditing {
  text: string;
}
```

- `text` is the current plain-text content of the input at submission time

| Type                                                     | Platforms         |
| -------------------------------------------------------- | ----------------- |
| `(event: NativeSyntheticEvent<OnSubmitEditing>) => void` | Android, iOS, Web |

### `onPasteImages` {#onpasteimages}

Called when the user pastes one or more images or GIFs into the input. See
[Inline images](/rich-text-formatting/inline-images) for the full picture.

- `images` - an array of objects with URI, MIME type, and dimensions for each
  pasted image/GIF

```ts
interface OnPasteImagesEvent {
  images: {
    uri: string;
    type: string;
    width: number;
    height: number;
  }[];
}
```

| Type                                                        | Platforms         |
| ----------------------------------------------------------- | ----------------- |
| `(event: NativeSyntheticEvent<OnPasteImagesEvent>) => void` | Android, iOS, Web |

:::note

On Web, `uri` is a blob URL (`blob:...`). Blob URLs hold memory until explicitly
released. Call `URL.revokeObjectURL(uri)` once you no longer need the image
(for example after the upload completes).

:::

### `placeholder` {#placeholder}

The placeholder text displayed when nothing has been typed yet. Disappears when
something is typed.

| Type     | Default | Platforms         |
| -------- | ------- | ----------------- |
| `string` | `''`    | Android, iOS, Web |

### `placeholderTextColor` {#placeholdertextcolor}

Input placeholder's text color.

| Type                                           | Default                 | Platforms         |
| ---------------------------------------------- | ----------------------- | ----------------- |
| [`color`](https://reactnative.dev/docs/colors) | input's [color](#style) | Android, iOS, Web |

### `ref` {#ref}

A React ref that lets you call any [ref methods](#ref-methods) on the input.

| Type                                           | Default | Platforms         |
| ---------------------------------------------- | ------- | ----------------- |
| `RefObject<EnrichedTextInputInstance \| null>` | -       | Android, iOS, Web |

### `returnKeyLabel` {#returnkeylabel}

Overrides the return key label with a custom string.

| Type     | Default | Platforms |
| -------- | ------- | --------- |
| `string` | -       | Android   |

### `returnKeyType` {#returnkeytype}

Specifies the label or icon shown on the keyboard's return key.

On Android, this prop is accepted but ignored, as `returnKeyType` doesn't work
with multiline inputs.

Accepts the standard React Native `ReturnKeyTypeOptions` values:
`'go' | 'next' | 'search' | 'send' | 'done' | 'default' | 'google' | 'join' | 'route' | 'yahoo' | 'emergency-call' | 'previous' | 'none'`.

| Type                   | Default     | Platforms |
| ---------------------- | ----------- | --------- |
| `ReturnKeyTypeOptions` | `'default'` | iOS, Web  |

:::note

On Web, this maps to the
[`enterkeyhint`](https://developer.mozilla.org/en-US/docs/Web/HTML/Global_attributes/enterkeyhint)
attribute on the editor element. Only the values the browser recognises
(`'enter'`, `'done'`, `'go'`, `'next'`, `'previous'`, `'search'`, `'send'`) have
a visible effect; unsupported values are silently ignored and fall back to
`'enter'`.

:::

### `sanitizationConfig` {#sanitizationconfig}

Web-only configuration for the HTML sanitization step, which runs on every HTML
entry and exit point — `defaultValue`, `.setValue()`, pasted HTML, `.getHTML()`,
and [`onChangeHtml`](#onchangehtml).

```ts
interface SanitizationConfig {
  linkRegex?: RegExp;
}
```

- `linkRegex` - a regular expression deciding which link URIs survive
  sanitization.

:::caution

`linkRegex` maps directly to DOMPurify's [`ALLOWED_URI_REGEXP`](https://github.com/cure53/DOMPurify#can-i-configure-dompurify), so it **replaces** the default allow-list rather than extending it. Because this regex affects all URI-containing attributes (e.g. `src` in `<img>`), remember to keep the standard protocols you still want to permit.

:::

```tsx
<EnrichedTextInput
  sanitizationConfig={{
    // Permit the usual protocols plus a custom "custom://" scheme.
    linkRegex:
      /^(?:(?:(?:f|ht)tps?|mailto|tel|custom):|[^a-z]|[a-z+.-]+(?:[^a-z+.:-]|$))/i,
  }}
/>
```

| Type                 | Default | Platforms |
| -------------------- | ------- | --------- |
| `SanitizationConfig` | -       | Web       |

:::note

This only controls what sanitization keeps. It is independent of the
[`linkRegex`](#linkregex) prop, which controls autolink detection while typing.
To both autolink and preserve a custom protocol, configure both.

:::

### `scrollEnabled` {#scrollenabled}

If `false`, the editor's internal scroll view is disabled and the component
expands to fit all content.

| Type      | Default | Platforms         |
| --------- | ------- | ----------------- |
| `boolean` | `true`  | Android, iOS, Web |

### `selectionColor` {#selectioncolor}

Color of the selection rectangle drawn over the selected text. On iOS, the
cursor (caret) also uses this color.

| Type                                           | Default        | Platforms         |
| ---------------------------------------------- | -------------- | ----------------- |
| [`color`](https://reactnative.dev/docs/colors) | system default | Android, iOS, Web |

### `style` {#style}

Controls the layout, dimensions, typography, borders, shadows, opacity, and
similar container-level appearance of the editable content container. See
[`EnrichedInputStyle`](#enrichedinputstyle-type) and
[Styling the input](/core-functionalities/styling-the-input).

| Type                 | Default | Platforms         |
| -------------------- | ------- | ----------------- |
| `EnrichedInputStyle` | -       | Android, iOS, Web |

### `submitBehavior` {#submitbehavior}

Controls what happens when the user presses the return/enter key.

- `'newline'` - inserts a new line (default for multiline inputs)
- `'submit'` - fires `onSubmitEditing` without inserting a new line
- `'blurAndSubmit'` - fires `onSubmitEditing` and blurs the input

| Type                                       | Default     | Platforms         |
| ------------------------------------------ | ----------- | ----------------- |
| `'submit' \| 'blurAndSubmit' \| 'newline'` | `'newline'` | Android, iOS, Web |

### `textShortcuts` {#textshortcuts}

An array of shortcuts that auto-convert typed patterns into styles. Each entry
maps a `trigger` string to a `style`. These shortcuts allow users to format text
similarly to modern Markdown editors by typing familiar patterns directly in the
input. See [Text shortcuts](/rich-text-formatting/text-shortcuts) for more
details.

```ts
interface TextShortcut {
  trigger: string;
  style: TextShortcutStyle;
}

type TextShortcutStyle =
  | 'bold'
  | 'italic'
  | 'underline'
  | 'strikethrough'
  | 'inline_code'
  | 'h1'
  | 'h2'
  | 'h3'
  | 'h4'
  | 'h5'
  | 'h6'
  | 'blockquote'
  | 'codeblock'
  | 'unordered_list'
  | 'ordered_list'
  | 'checkbox_list';
```

- `trigger` is the typed pattern that activates the shortcut
- `style` is the style to apply when the trigger completes

**[Paragraph styles](/fundamentals/html-format-and-supported-tags#paragraph-tags)**
fire at the start of a paragraph (e.g. `# ` → H1, `- ` → unordered list).
Supported styles: `h1`–`h6`, `blockquote`, `codeblock`, `unordered_list`,
`ordered_list`, `checkbox_list`.

:::note

Paragraph shortcuts are only effective on plain paragraphs. If the paragraph
already has an active paragraph style (for example it is already a heading or a
list item), typing the trigger pattern has no effect.

:::

**[Inline styles](/fundamentals/html-format-and-supported-tags#inline-tags)**
fire when a closing delimiter is typed around text (e.g. `**text**` → bold). The
trigger is the delimiter string (e.g. `**`, `*`, `~~`). Supported styles:
`bold`, `italic`, `underline`, `strikethrough`, `inline_code`.

:::note

Style rules still apply to shortcut-triggered styles: if the target style is
**blocked** by another currently active style (e.g. bold inside a codeblock),
the shortcut has no effect. If the target style **conflicts** with another
active inline style, the conflicting style is removed when the new one is
applied. See [Supported tags](/fundamentals/html-format-and-supported-tags) for the full
conflict and blocking rules.

:::

Default value:

```ts
[
  { trigger: '- ', style: 'unordered_list' },
  { trigger: '1. ', style: 'ordered_list' },
];
```

| Type             | Default   | Platforms         |
| ---------------- | --------- | ----------------- |
| `TextShortcut[]` | see above | Android, iOS, Web |

:::tip

Pass an empty array to disable all shortcuts.

:::

### `useHtmlNormalizer` {#usehtmlnormalizer}

If `true`, external HTML pasted or inserted into the input (for example from
Google Docs, Word, or web pages) is normalized into the canonical tag subset
that the enriched parser understands. See
[Normalization](/fundamentals/core-concepts#normalization).

| Type      | Default | Platforms         |
| --------- | ------- | ----------------- |
| `boolean` | `true`  | Android, iOS, Web |

### `androidExperimentalSynchronousEvents` {#androidexperimentalsynchronousevents}

:::caution

Experimental. This feature has not been thoroughly tested. It may be enabled by
default in a future release.

:::

If `true`, Android uses experimental synchronous events. This can prevent input
flickering when updating component size.

| Type      | Default | Platforms |
| --------- | ------- | --------- |
| `boolean` | `false` | Android   |

### `ViewProps` {#viewprops}

The input inherits
[ViewProps](https://reactnative.dev/docs/view#props), but some of those props
may not be supported.

| Type        | Default | Platforms    |
| ----------- | ------- | ------------ |
| `ViewProps` | -       | Android, iOS |

## Ref methods

All methods should be called on the input's [`ref`](#ref).

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

### `.getHTML()`

```ts
getHTML: () => Promise<string>;
```

Returns a Promise that resolves with the current HTML content of the input.
Useful when you need the HTML on demand (for example when saving) without the
performance overhead of continuous parsing via `onChangeHtml`.

### `.setImage()`

```ts
setImage: (src: string, width: number, height: number) => void;
```

Sets an inline image at the current selection. See
[Inline images](/rich-text-formatting/inline-images) for more details.

- `src: string` - absolute path to a file or remote image address
- `width: number` - width of the image
- `height: number` - height of the image

:::note

It's the developer's responsibility to provide proper width and height, which
may require calculating aspect ratio. If the image source is incorrect, a static
placeholder is displayed.

:::

### `.setLink()`

```ts
setLink: (start: number, end: number, text: string, url: string) => void;
```

Sets a link at the given place with the given displayed text and URL. The link
replaces any text between `start` and `end`. Setting a link with `start` equal
to `end` inserts it in place. See [Links](/rich-text-formatting/links) for more
details.

- `start: number` - starting index where the link should be
- `end: number` - first index behind the new link's ending index
- `text: string` - displayed text of the link
- `url: string` - URL of the link

:::note

Using this method with `text=""` will result in removal of the text marked by the `start` and `end` indexes.

;;;

### `.removeLink()`

```ts
removeLink: (start: number, end: number) => void;
```

Removes link styling from any links found within the given range. The text
content is preserved; only the link attributes are stripped.

- `start: number` - starting index of the range to remove links from
- `end: number` - first index behind the range's ending index

### `.setMention()`

```ts
setMention: (
  indicator: string,
  text: string,
  attributes?: Record<string, string>
) => void;
```

Sets the currently edited mention with a given indicator, displayed text, and
custom attributes. See [Mentions](/rich-text-formatting/mentions) for more
details.

- `indicator: string` - indicator of the set mention
- `text: string` - text displayed for the mention; anything the user typed is
  replaced by that text. The mention indicator isn't added to that text
- `attributes?: Record<string, string>` - additional custom attributes for the
  mention, preserved through parsing to and from HTML

:::caution

The attributes you pass to `setMention` ride along in the HTML
and survive a round-trip through `getHTML` / `setValue`. Prefix custom keys with
`data-` if they need to outlive a sanitizer - see the note in
[Mentions](/rich-text-formatting/mentions).

:::

### `.setValue()`

```ts
setValue: (value: string) => void;
```

Sets the input's value.

- `value: string` - value to set; either a supported HTML string or raw text

### `.setSelection()`

```ts
setSelection: (start: number, end: number) => void;
```

Sets the selection at the given indexes.

- `start: number` - starting index of the selection
- `end: number` - first index after the selection's ending index; for a cursor
  with no selection, `start` equals `end`

### `.setTextAlignment()`

```ts
setTextAlignment: (
  alignment: 'left' | 'center' | 'right' | 'justify' | 'auto'
) => void;
```

Sets text alignment for the paragraph(s) at the current selection. When inside a
list, the alignment is applied to all contiguous list items. See
[Text alignment](/rich-text-formatting/text-alignment) for more details.

- `alignment` - desired text alignment; use `'auto'` to reset to the system
  natural alignment

:::note

On Android, `'justify'` is not supported. Calling
`setTextAlignment('justify')` does not apply justified text - the paragraph ends
up with natural alignment, the same as `'auto'`.

:::

### `.startMention()`

```ts
startMention: (indicator: string) => void;
```

Starts a mention with the given indicator at the cursor/selection.

- `indicator: string` - indicator that starts the new mention

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

Toggles heading 1 (H1) style at the current selection.

### `.toggleH2()`

```ts
toggleH2: () => void;
```

Toggles heading 2 (H2) style at the current selection.

### `.toggleH3()`

```ts
toggleH3: () => void;
```

Toggles heading 3 (H3) style at the current selection.

### `.toggleH4()`

```ts
toggleH4: () => void;
```

Toggles heading 4 (H4) style at the current selection.

### `.toggleH5()`

```ts
toggleH5: () => void;
```

Toggles heading 5 (H5) style at the current selection.

### `.toggleH6()`

```ts
toggleH6: () => void;
```

Toggles heading 6 (H6) style at the current selection.

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

Converts the current selection into an ordered list.

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

Converts the current selection into an unordered list.

### `.toggleCheckboxList()`

```ts
toggleCheckboxList: (checked: boolean) => void;
```

Converts the current selection into an unordered list with checkboxes as items.
Each checkbox can be checked or unchecked. The user can later toggle each
checkbox individually by tapping on it.

- `checked: boolean` - whether the checkboxes should be checked or unchecked by
  default

See [Lists](/rich-text-formatting/lists) for more on all list types.

## HtmlStyle type

Allows customizing HTML styles inside the editor.

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
  h4?: {
    fontSize?: number;
    bold?: boolean;
  };
  h5?: {
    fontSize?: number;
    bold?: boolean;
  };
  h6?: {
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
  ulCheckbox?: {
    boxColor?: ColorValue;
    boxSize?: number;
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

### h1/h2/h3/h4/h5/h6 (headings)

- `fontSize` - size of the heading's font. Defaults to `32` for `H1`, `24` for
  `H2`, `20` for `H3`, `16` for `H4`, `14` for `H5`, `12` for `H6`
- `bold` - whether the heading should be bolded; defaults to `false`

### blockquote

- `borderColor` - color of the rectangular border drawn to the left of
  blockquote text; takes a [color](https://reactnative.dev/docs/colors) value,
  defaults to `darkgray`
- `borderWidth` - width of that border; defaults to `4`
- `gapWidth` - width of the gap between the border and the blockquote text;
  defaults to `16`
- `color` - color of blockquote text; takes a
  [color](https://reactnative.dev/docs/colors) value; if not set, uses the
  input's [color](#style)

### codeblock

- `color` - color of codeblock text; takes a
  [color](https://reactnative.dev/docs/colors) value, defaults to `black`
- `borderRadius` - radius of the codeblock's border; defaults to `8`
- `backgroundColor` - codeblock background color; takes a
  [color](https://reactnative.dev/docs/colors) value, defaults to `darkgray`

### code (inline code)

- `color` - color of inline code text; takes a
  [color](https://reactnative.dev/docs/colors) value, defaults to `red`
- `backgroundColor` - inline code background color; takes a
  [color](https://reactnative.dev/docs/colors) value, defaults to `darkgray`

### a (link)

- `color` - color of link text; takes a
  [color](https://reactnative.dev/docs/colors) value, defaults to `blue`
- `textDecorationLine` - whether links are underlined; `'underline'` or
  `'none'`, defaults to `'underline'`

### mention

If only a single config is given, the style applies to all mention types. You
can also set a different config for each `mentionIndicator`; then the prop
should be a record with indicators as keys and configs as values.

- `color` - color of mention text; takes a
  [color](https://reactnative.dev/docs/colors) value, defaults to `blue`
- `backgroundColor` - mention background color; takes a
  [color](https://reactnative.dev/docs/colors) value, defaults to `yellow`
- `textDecorationLine` - whether mentions are underlined; `'underline'` or
  `'none'`, defaults to `'underline'`

:::tip

You can also create a default `mention` style config, by using the `'default'` key.

```tsx
htmlStyle={{
  mention: {
    'default': { color: '#2563eb', backgroundColor: '#dbeafe' },
    '#': { color: '#16a34a', backgroundColor: '#dcfce7' },
  },
}}
```

This way you can create a style for any mention indicator to fallback if it doesn't have one fully defined.

:::

### ol (ordered list)

By marker, we mean the number that denotes consecutive lines of the list.

- `gapWidth` - gap between the marker and the list item's text; defaults to `16`
- `marginLeft` - margin to the left of the marker (between the marker and the
  input's left edge); defaults to `16`
- `markerFontWeight` - font weight of the marker; takes a
  [fontWeight](https://reactnative.dev/docs/text-style-props#fontweight) value;
  if not set, defaults to the input's [fontWeight](#style)
- `markerColor` - text color of the marker; takes a
  [color](https://reactnative.dev/docs/colors) value; if not set, defaults to
  the input's [color](#style)

:::note

As you may have noticed, there is no way to define an ordered list marker’s width (unlike other list styles).
This is because the marker value changes, so its width is dynamic.
The marker is rendered _inside_ the space defined by `marginLeft` (right-aligned within it), so keep this in mind when styling your UI.

:::

### ul (unordered list)

By bullet, we mean the dot that begins each line of the list.

- `bulletColor` - color of the bullet; takes a
  [color](https://reactnative.dev/docs/colors) value, defaults to `black`
- `bulletSize` - height and width of the bullet; defaults to `8`
- `marginLeft` - margin to the left of the bullet; defaults to `16`
- `gapWidth` - gap between the bullet and the list item's text; defaults to `16`

### ulCheckbox (checkbox list)

Unordered list with checkboxes instead of bullets.

- `boxColor` - color of the checkbox; takes a
  [color](https://reactnative.dev/docs/colors) value, defaults to `blue`
- `boxSize` - height and width of the checkbox; defaults to `24`
- `marginLeft` - margin to the left of the checkbox; defaults to `16`
- `gapWidth` - gap between the checkbox and the list item's text; defaults to
  `16`

## EnrichedInputStyle type

Defines the [`style`](#style) prop's shape. This type is a subset of React
Native's [TextStyle](https://reactnative.dev/docs/text-style-props) - some
properties are not supported (for example `textAlign`, `textDecorationLine`,
`justifyContent`). Certain properties are platform-specific and include an
`@platform` directive in the type definition.

Type definition

<details>
<summary>Type definition</summary>

```ts
export interface EnrichedInputStyle {
  // Layout / FlexStyle
  alignSelf?: FlexStyle['alignSelf'];
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
  position?: FlexStyle['position'];
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
```

</details>

## Remarks

- The input is uncontrolled. Change content and formatting through ref methods;
  observe changes through events. See
  [Core concepts](/fundamentals/core-concepts#the-input-is-uncontrolled).
- Prefer [`getHTML`](#gethtml) over continuous `onChangeHtml` when you only need
  HTML at specific moments.
- Sanitizing HTML is your responsibility. See
  [Core concepts](/fundamentals/core-concepts#html-is-the-source-of-truth).
- For the full list of supported tags and style conflicts, see
  [HTML format and supported tags](/fundamentals/html-format-and-supported-tags).
