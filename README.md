<img src="https://github.com/user-attachments/assets/abc75d3b-495b-4a76-a72f-d87ce3ca1ff9" alt="react-native-enriched by Software Mansion" width="100%">

# react-native-enriched

`react-native-enriched` is a powerful React Native library that exposes a rich text editor component:

- ⚡ Fully native text input component
- 🕹️ Synchronous text styling
- 🔍 Live styling detection and HTML parsing
- 🎨 Customizable styles
- 📱 Mobile platforms support
- 🏛 Supports only the New Architecture

`EnrichedTextInput`, the rich text editor component is an uncontrolled input. This means that it doesn't use any state or props to store its value, but instead directly interacts with the underlying platform-specific components. Thanks to this, the component is really performant and simple to use while offering complex and advanced features no other solution has.

Built by [Software Mansion](https://swmansion.com/) and sponsored by [Filament](https://filament.dm/).

[<img width="128" height="69" alt="Software Mansion Logo" src="https://github.com/user-attachments/assets/f0e18471-a7aa-4e80-86ac-87686a86fe56" />](https://swmansion.com/)
&nbsp;&nbsp;&nbsp;
<img width="48" height="48" alt="" src="https://github.com/user-attachments/assets/46c6bf1f-2685-497e-b699-d5a94b2582a3" />
&nbsp;&nbsp;&nbsp;
[<img width="80" height="80" alt="Filament Logo" src="https://github.com/user-attachments/assets/4103ab79-da34-4164-aa5f-dcf08815bf65" />](https://filament.dm/)

\
Since 2012 [Software Mansion](https://swmansion.com) is a software agency with experience in building web and mobile apps. We are Core React Native Contributors and experts in dealing with all kinds of React Native issues.
We can help you build your next dream product –
[Hire us](https://swmansion.com/contact/projects?utm_source=react-native-enriched&utm_medium=readme).

## Table of Contents

- [Prerequisites](#prerequisites)
- [Installation](#installation)
- [Usage](#usage)
- [Non Parametrized Styles](#non-parametrized-styles)
- [Links](#links)
- [Mentions](#mentions)
- [Inline Images](#inline-images)
- [Style Detection](#style-detection)
- [Other Events](#other-events)
- [Customizing \<EnrichedTextInput /> styles](#customizing-enrichedtextinput--styles)
- [API Reference](#api-reference)
- [Future Plans](#future-plans)
- [Contributing](#contributing)
- [License](#license)

## Prerequisites

- `react-native-enriched` currently supports only Android and iOS platforms
- It works only with [the React Native New Architecture (Fabric)](https://reactnative.dev/architecture/landing-page) and supports following React Native releases: `0.79`, `0.80`, `0.81` and `0.82`

## Installation

### Bare react native app

#### 1. Install the library

```sh
yarn add react-native-enriched
```

#### 2. Install iOS dependencies

The library includes native code so you will need to re-build the native app to use it.

```sh
cd ios && bundler install && bundler exec pod install
```

### Expo app

#### 1. Install the library

```sh
npx expo install react-native-enriched
```

#### 2. Run prebuild

The library includes native code so you will need to re-build the native app to use it.

```sh
npx expo prebuild
```

> [!NOTE]
> The library won't work in Expo Go as it needs native changes.

## Usage

Here's a simple example of an input that lets you toggle bold on its text and shows whether bold is currently active via the button color.

```tsx
import { EnrichedTextInput } from 'react-native-enriched';
import type {
  EnrichedTextInputInstance,
  OnChangeStateEvent,
} from 'react-native-enriched';
import { useState, useRef } from 'react';
import { View, Button, StyleSheet } from 'react-native';

export default function App() {
  const ref = useRef<EnrichedTextInputInstance>(null);

  const [stylesState, setStylesState] = useState<OnChangeStateEvent | null>();

  return (
    <View style={styles.container}>
      <EnrichedTextInput
        ref={ref}
        onChangeState={(e) => setStylesState(e.nativeEvent)}
        style={styles.input}
      />
      <Button
        title="Toggle bold"
        color={stylesState?.isBold ? 'green' : 'gray'}
        onPress={() => ref.current?.toggleBold()}
      />
    </View>
  );
}

const styles = StyleSheet.create({
  container: {
    flex: 1,
    justifyContent: 'center',
    alignItems: 'center',
  },
  input: {
    width: '100%',
    fontSize: 20,
    padding: 10,
    maxHeight: 200,
    backgroundColor: 'lightgray',
  },
});

```

Summary of what happens here:

1. Any methods imperatively called on the input to e.g. toggle some style must be used through a `ref` of `EnrichedTextInputInstance` type. Here, `toggleBold` method that is called on the button press calls `ref.current?.toggleBold()`, which toggles the bold styling within the current selection.
2. All the active styles info is emitted by `onChangeState` event. Set up a proper callback that accepts a `NativeSyntheticEvent<OnChangeStateEvent>` argument, and you can access an object with boolean properties indicating which styles are active, such as `isBold` in the example. Here, this info is stored in a React state and used to change colors on the button.

## Non Parametrized Styles

Supported styles:

- bold
- italic
- underline
- strikethrough
- inline code
- H1 heading
- H2 heading
- H3 heading
- codeblock
- blockquote
- ordered list
- unordered list

> [!NOTE]
> The iOS doesn't support codeblocks just yet, but it's planned in the near future!

Each of the styles can be toggled the same way as in the example from [usage section](#usage); call a proper `toggle` function on the component ref.

Each call toggles the style within the current text selection. We can still divide styles into two categories based on how they treat the selection:

- Inline styles (bold, italic, underline, strikethrough, inline code). They are being toggled on exactly the character range that is currently selected. When toggling the style with just the cursor in place (no selection), the style is ready to be used and will be applied to the next characters that the user inputs.

- Paragraph styles (headings, codeblock, blockquote, lists). They are being toggled on the entire paragraph that the selection is in. By paragraph we mean a part of the text between two newlines (enters) or the text's beginning/ending.
If the selection spans more than one paragraph, logically more of them will be affected by the toggle. Toggling these styles with the cursor in place (no selection) makes changes to the very paragraph the cursor is in.

## Links

The links are here, just like in any other editor, a piece of text with a URL attributed to it. They can be added in two ways: automatically or manually.

### Automatic links detection

`react-native-enriched` automatically detects words that appear to be some URLs and makes them links. Currently, we are using pretty naive approach to detect whether text can be treated as a link or not. On iOS it's a pretty simple regex, on Android we are using URL regex provided by the system.

### Applying links manually

Links can also be added by calling [setLink](#setlink) method on the input ref:

The `start`, `end` and `text` arguments for the method can be easily taken from [onChangeSelection](#onchangeselection) event payload as it returns exact `start` and `end` of the selection and the `text` it spans. This way, you just set the underlying URL to whatever is selected in there.

Passing a different `text` than the one in the selection will properly replace it before applying the link.

A complete example of a setup that supports both setting links on the selected text, as well as putting them in the place of cursor and editing existing links can be found in the example app code.

## Mentions

Mentions are meant to be a customisable style that lets you put mentioning phrases in the input, e.g. `@someone` or `#some_channel` or `[any_character_you_like]something`.

### Mention Indicators

There is a [mentionIndicators](#mentionindicators) prop that lets you define what characters can start a mention. By default, it is set to `[ @ ]`, meaning that typing a `@` character in the input will start the creation of a mention.

### Starting a mention

There are two ways in which a mention can be started; either by typing one of the `mentionIndicators` set or by calling a [startMention](#startmention) method on the input ref.

### Mention related events

`react-native-enriched` emits 3 different events that help handling mentions' editing:

- [onStartMention](#onstartmention) is emitted whenever mention is started in one of the ways from the [previous section](#starting-a-mention) or the user has come back (moved selection) to some unfinished mention they have started. It can be used for opening proper tools you use in the app to edit a mention (e.g. a list for choosing from users or channels that the mention will affect).
- [onChangeMention](#onchangemention) is emitted whenever user put or removed some characters after a mention indicator. This way you can react to active mention editing by, for example, filtering users in your displayed list based on the typed text.
- [onEndMention](#onendmention) is emitted whenever user is no longer editing a mention: they might have put a space or changed the cursor position to be no longer near the indicator. You can use it to hide appropriate tools that were used for mention editing.

### Setting a mention

Whenever you feel ready with the currently edited mention (so most likely user chooses something from your additional mention editor), you can complete it by calling [setMention](#setmention) ref method.

## Inline images

You can insert an image into the input using [setImage](#setimage) ref method.

The image will be put into a single line in the input and will affect the line's height as well as input's height. Keep in mind, that image will replace currently selected text or insert into the cursor position if there is no text selection.

> [!NOTE]
> The iOS doesn't support inline images just yet, but it's planned in the near future!

## Style Detection

All of the above styles can be detected with the use of [onChangeState](#onchangestate) event payload.

You can find some examples in the [usage section](#usage) or in the example app.

## Other Events

`react-native-enriched` emits a few more events that may be of use:

- [onFocus](#onfocus) - emits whenever input focuses.
- [onBlur](#onblur) - emits whenever input blurs.
- [onChangeText](#onchangetext) - returns the input's text anytime it changes.
- [onChangeHtml](#onchangehtml) - returns HTML string parsed from current input text and styles anytime it would change. As parsing the HTML on each input change is a pretty expensive operation, not assigning the event's callback will speed up iOS input a bit. We are considering adding some API to improve it, see [future plans](#future-plans).
- [onChangeSelection](#onchangeselection) - returns all the data needed for working with selections (as of now it's mainly useful for [links](#links)).
- [onLinkDetected](#onlinkdetected) - returns link's detailed info whenever user selection is near one.
- [onMentionDetected](#onmentiondetected) - returns mention's detailed info whenever user selection is near one.

## Customizing \<EnrichedTextInput /> styles

`react-native-enriched` allows customizing styles of the `<EnrichedTextInput />` component.  See [htmlStyle](#htmlstyle) prop.

## API Reference

### Props

#### `autoFocus`

If `true`, focuses the input.

| Type   | Default Value | Platform |
|--------|---------------|----------|
| `bool` | `false`       | Both     |

#### `autoCapitalize`

Tells input to automatically capitalize certain characters.

- `characters`: all characters.
- `words`: first letter of each word.
- `sentences`: first letter of each sentence.
- `none`: don't auto capitalize anything.

| Type                                               | Default Value | Platform |
|----------------------------------------------------|---------------|----------|
| `'none' \| 'sentences' \| 'words' \| 'characters'` | `'sentences'` | Both     |

#### `cursorColor`

When provided it will set the color of the cursor (or "caret") in the component.

| Type                                           | Default Value  | Platform |
|------------------------------------------------|----------------|----------|
| [`color`](https://reactnative.dev/docs/colors) | system default | Android  |

#### `defaultValue`

Provides an initial value for the input. If the string is a valid HTML output of the `EnrichedTextInput` component (or other HTML that the parser will accept), proper styles will be applied.

| Type     | Default Value | Platform |
|----------|---------------|----------|
| `string` | -             | Both     |

#### `editable`

If `false`, text is not editable.

| Type   | Default Value | Platform |
|--------|---------------|----------|
| `bool` | `true`        | Both     |

#### `htmlStyle`

A prop for customizing styles appearances.

| Type                           | Default Value                                      | Platform |
|--------------------------------|----------------------------------------------------|----------|
| [`HtmlStyle`](#htmlstyle-type) | default values from [`HtmlStyle`](#htmlstyle-type) | Both     |

#### `mentionIndicators`

The recognized mention indicators. Each item needs to be a 1 character long string.

| Type              | Default Value | Platform |
|-------------------|---------------|----------|
| array of `string` | `['@']`       | Both     |

#### `onBlur`

Callback that's called whenever the input loses focused (is blurred).

| Type         | Default Value | Platform |
|--------------|---------------|----------|
| `() => void` | -             | Both     |

#### `onChangeHtml`

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

#### `onChangeMention`

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

#### `onChangeSelection`

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

#### `onChangeState`

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

#### `onChangeText`

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

#### `onEndMention`

Callback that is called when the user no longer edits a mention actively - has moved the cursor somewhere else or put a space and the cursor isn't within the edited mention.

- `indicator` is the indicator of the mention that was being edited.

| Type                          | Default Value | Platform |
|-------------------------------|---------------|----------|
| `(indicator: string) => void` | -             | Both     |

#### `onFocus`

Callback that's called whenever the input is focused.

| Type         | Default Value | Platform |
|--------------|---------------|----------|
| `() => void` | -             | Both     |

#### `onLinkDetected`

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

#### `onMentionDetected`

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

#### `onStartMention`

Callback that gets called whenever a mention editing starts (after placing the indicator).

- `indicator` is the indicator of the mention that begins editing.

| Type                          | Default Value | Platform |
|-------------------------------|---------------|----------|
| `(indicator: string) => void` | -             | Both     |

#### `placeholder`

The placeholder text that is displayed in the input if nothing has been typed yet. Disappears when something is typed.

| Type     | Default Value | Platform |
|----------|---------------|----------|
| `string` | `''`          | Both     |

#### `placeholderTextColor`

Input placeholder's text color.

| Type                                           | Default Value           | Platform |
|------------------------------------------------|-------------------------|----------|
| [`color`](https://reactnative.dev/docs/colors) | input's [color](#style) | Both     |

#### `ref`

A React ref that lets you call any ref methods on the input.

| Type                                           | Default Value | Platform |
|------------------------------------------------|---------------|----------|
| `RefObject<EnrichedTextInputInstance \| null>` | -             | Both     |

#### `selectionColor`

Color of the selection rectangle that gets drawn over the selected text. On iOS, the cursor (caret) also gets set to this color.

| Type                                           | Default Value  | Platform |
|------------------------------------------------|----------------|----------|
| [`color`](https://reactnative.dev/docs/colors) | system default | Both     |

#### `style`

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

#### `ViewProps`

The input inherits [ViewProps](https://reactnative.dev/docs/view#props), but keep in mind that some of the props may not be supported.

#### `androidExperimentalSynchronousEvents` - EXPERIMENTAL

If true, Android will use experimental synchronous events. This will prevent from input flickering when updating component size. However, this is an experimental feature, which has not been thoroughly tested. We may decide to enable it by default in a future release.

| Type   | Default Value | Platform |
|--------|---------------|----------|
| `bool` | `false`       | Android  |

### Ref Methods

All the methods should be called on the input's [ref](#ref).

#### `.blur()`

```ts
blur: () => void;
```

Blurs the input.

#### `.focus()`

```ts
focus: () => void;
```

Focuses the input.

#### `.setImage()`

> [!NOTE]
> This function is Android only as iOS doesn't support inline images just yet.

```ts
setImage: (src: string) => void;
```

Sets the [inline image](#inline-images) at the current selection.

- `src: string` - the absolute path to the image.

#### `.setLink()`

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

#### `.setMention()`

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

#### `.setValue()`

```ts
setValue: (value: string) => void;
```

Sets the input's value.

- `value: string` - value to set, it can either be `react-native-enriched` supported HTML string or raw text.

#### `.startMention()`

```ts
startMention: (indicator: string) => void;
```

Starts a mention with the given indicator. It gets put at the cursor/selection.

- `indicator: string` - the indicator that starts the new mention.

#### `.toggleBlockQuote()`

```ts
toggleBlockQuote: () => void;
```

Toggles blockquote style at the current selection.

#### `.toggleBold()`

```ts
toggleBold: () => void;
```

Toggles bold formatting at the current selection.

#### `.toggleCodeBlock()`

> [!NOTE]
> This function is Android only as iOS doesn't support codeblocks just yet.

```ts
toggleCodeBlock: () => void;
```

Toggles codeblock formatting at the current selection.

#### `.toggleH1()`

```ts
toggleH1: () => void;
```

Toggles heading 1 (h1) style at the current selection.

#### `.toggleH2()`

```ts
toggleH2: () => void;
```

Toggles heading 2 (h2) style at the current selection.

#### `.toggleH3()`

```ts
toggleH3: () => void;
```

Toggles heading 3 (h3) style at the current selection.

#### `.toggleInlineCode()`

```ts
toggleInlineCode: () => void;
```

Applies inline code formatting to the current selection.

#### `.toggleItalic()`

```ts
toggleItalic: () => void;
```

Toggles italic formatting at the current selection.

#### `.toggleOrderedList()`

```ts
toggleOrderedList: () => void;
```

Converts current selection into an ordered list.

#### `.toggleStrikeThrough()`

```ts
toggleStrikeThrough: () => void;
```

Applies strikethrough formatting to the current selection.

#### `.toggleUnderline()`

```ts
toggleUnderline: () => void;
```

Applies underline formatting to the current selection.

#### `.toggleUnorderedList()`

```ts
toggleUnorderedList: () => void;
```

Converts current selection into an unordered list.

### HtmlStyle type

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
  img?: {
    width?: number;
    height?: number;
  };
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

#### h1/h2/h3 (headings)

- `fontSize` is the size of the heading's font, defaults to `32`/`24`/`20` for h1/h2/h3.
- `bold` defines whether the heading should be bolded, defaults to `false`.

> [!NOTE]
> On iOS, the headings cannot have same `fontSize` as the component's `fontSize`. Doing so results in unexpected behavior.

#### blockquote

- `borderColor` defines the color of the rectangular border drawn to the left of blockquote text. Takes [color](https://reactnative.dev/docs/colors) value, defaults to `darkgray`.
- `borderWidth` sets the width of the said border, defaults to `4`.
- `gapWidth` sets the width of the gap between the border and the blockquote text, defaults to `16`.
- `color` defines the color of blockquote's text. Takes [color](https://reactnative.dev/docs/colors) value, if not set makes the blockquote text the same color as the input's [color prop](#style).

#### codeblock

- `color` defines the color of codeblock text, takes [color](https://reactnative.dev/docs/colors) value and defaults to `black`.
- `borderRadius` sets the radius of codeblock's border, defaults to 8.
- `backgroundColor` is the codeblock's background color, takes [color](https://reactnative.dev/docs/colors) value and defaults to `darkgray`.

#### code (inline code)

- `color` defines the color of inline code's text, takes [color](https://reactnative.dev/docs/colors) value and defaults to `red`.
- `backgroundColor` is the inline code's background color, takes [color](https://reactnative.dev/docs/colors) value and defaults to `darkgray`.

#### a (link)

- `color` defines the color of link's text, takes [color](https://reactnative.dev/docs/colors) value and defaults to `blue`.
- `textDecorationLine` decides if the links are underlined or not, takes either `underline` or `none` and defaults to `underline`

#### mention

If only a single config is given, the style applies to all mention types. You can also set a different config for each mentionIndicator that has been defined, then the prop should be a record with indicators as a keys and configs as their values.

- `color` defines the color of mention's text, takes [color](https://reactnative.dev/docs/colors) value and defaults to `blue`.
- `backgroundColor` is the mention's background color, takes [color](https://reactnative.dev/docs/colors) value and defaults to `yellow`.
- `textDecorationLine` decides if the mentions are underlined or not, takes either `underline` or `none` and defaults to `underline`.

#### img (inline image)

- `width` is the width of the inline image, defaults to `80`.
- `height` is the height of the inline image, defaults to `80`.

#### ol (ordered list)

By marker we mean the number that denotes next lines of the list.

- `gapWidth` sets the gap between the marker and the list item's text, defaults to  `16`.
- `marginLeft` sets the margin to the left of the marker (between the marker and input's left edge), defaults to `16`.
- `markerFontWeight` defines the font weight of the marker, takes a [fontWeight](https://reactnative.dev/docs/text-style-props#fontweight) value and if not set, defaults to the same font weight as input's [fontWeight prop](#style).
- `markerColor` sets the text color of the marker, takes [color](https://reactnative.dev/docs/colors) value and if not set, defaults to the same color as input's [color prop](#style).

#### ul (unordered list)

By bullet we mean the dot that begins each line of the list.

- `bulletColor` defines the color of the bullet, takes [color](https://reactnative.dev/docs/colors) value and defaults to `black`.
- `bulletSize` sets both the height and the width of the bullet, defaults to `8`.
- `marginLeft` is the margin to the left of the bullet (between the bullet and input's left edge), defaults to `16`.
- `gapWidth` sets the gap between the bullet and the list item's text, defaults to `16`.

## Future Plans

- Adding Codeblocks and Inline Images to iOS input.
- Making some optimizations around `onChangeHtml` event, maybe some imperative API to get the HTML output.
- Creating `EnrichedText` text component that supports our HTML output format with all additional interactions like pressing links or mentions.
- Adding API for custom link detection regex.
- Web library implementation via `react-native-web`.

## Contributing

See the [contributing guide](CONTRIBUTING.md) to learn how to contribute to the repository and the development workflow.

## License

`react-native-enriched` library is licensed under [The MIT License](./LICENSE).
