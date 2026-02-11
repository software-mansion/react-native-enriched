<img src="https://github.com/user-attachments/assets/6963e203-38c8-4209-b1b2-1ff65f6765f9" alt="react-native-enriched by Software Mansion" width="100%">

# react-native-enriched

`react-native-enriched` is a powerful React Native library that exposes a rich text editor component:

- ⚡ Fully native text input component
- 🕹️ Synchronous text styling
- 🔍 Live styling detection and HTML parsing
- 🎨 Customizable styles
- 📱 Mobile platforms support
- 🏛 Supports only the New Architecture

`EnrichedTextInput`, the rich text editor component is an uncontrolled input. This means that it doesn't use any state or props to store its value, but instead directly interacts with the underlying platform-specific components. Thanks to this, the component is really performant and simple to use while offering complex and advanced features no other solution has.

![react-native-enriched-demo](https://github.com/user-attachments/assets/a2c968c0-9b85-492f-ac71-af64ef231fbf)

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
- [Known limitations](#known-limitations)
- [Future Plans](#future-plans)
- [Contributing](#contributing)
- [License](#license)

## Prerequisites

- `react-native-enriched` currently supports only Android and iOS platforms
- It works only with [the React Native New Architecture (Fabric)](https://reactnative.dev/architecture/landing-page) and supports following React Native releases: `0.81`, `0.82` and `0.83`
- If you would like to use `react-native-enriched` in React Native `0.79` or `0.80` use `react-native-enriched 0.3.x`.

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
        title={stylesState?.isBold ? 'Unbold' : 'Bold'}
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
2. All style state information is emitted by the `onChangeState` event. Set up a proper callback that accepts a `NativeSyntheticEvent<OnChangeStateEvent>` argument. The event payload provides a nested object for each style (e.g., `bold`, `italic`), containing three properties to guide your UI logic:

- `isActive`: Indicates if the style is currently applied (highlight the button).
- `isBlocking`: Indicates if the style is blocked by another active style (disable the button).
- `isConflicting`: Indicates if the style is in conflict with another active style.

## Non Parametrized Styles

Supported styles:

- bold
- italic
- underline
- strikethrough
- inline code
- H1, H2, H3, H4, H5 and H6 headings
- codeblock
- blockquote
- ordered list
- unordered list
- checkbox list

Each of the styles can be toggled the same way as in the example from [usage section](#usage); call a proper `toggle` function on the component ref.

Each call toggles the style within the current text selection. We can still divide styles into two categories based on how they treat the selection:

- Inline styles (bold, italic, underline, strikethrough, inline code). They are being toggled on exactly the character range that is currently selected. When toggling the style with just the cursor in place (no selection), the style is ready to be used and will be applied to the next characters that the user inputs.

- Paragraph styles (headings, codeblock, blockquote, lists). They are being toggled on the entire paragraph that the selection is in. By paragraph, we mean a part of the text between two newlines (enters) or the text's beginning/ending.
  If the selection spans more than one paragraph, logically more of them will be affected by the toggle. Toggling these styles with the cursor in place (no selection) makes changes to the very paragraph the cursor is in.

## Links

The links are here, just like in any other editor, a piece of text with a URL attributed to it. They can be added in two ways: automatically or manually.

### Automatic links detection

`react-native-enriched` automatically detects words that appear to be some URLs and makes them links.
You can customize this behavior by providing your own regular expression via [linkRegex](docs/API_REFERENCE.md#linkregex) prop.

### Applying links manually

Links can also be added by calling [`setLink`](docs/API_REFERENCE.md#setlink) method on the input ref:

The `start`, `end` and `text` arguments for the method can be easily taken from [onChangeSelection](docs/API_REFERENCE.md#onchangeselection) event payload as it returns exact `start` and `end` of the selection and the `text` it spans. This way, you just set the underlying URL to whatever is selected in there.

Passing a different `text` than the one in the selection will properly replace it before applying the link.

A complete example of a setup that supports both setting links on the selected text, as well as putting them in the place of cursor and editing existing links can be found in the example app code.

## Mentions

Mentions are meant to be a customisable style that lets you put mentioning phrases in the input, e.g. `@someone` or `#some_channel` or `[any_character_you_like]something`.

### Mention Indicators

There is a [mentionIndicators](docs/API_REFERENCE.md#mentionindicators) prop that lets you define what characters can start a mention. By default, it is set to `[ @ ]`, meaning that typing a `@` character in the input will start the creation of a mention.

### Starting a mention

There are two ways in which a mention can be started; either by typing one of the `mentionIndicators` set or by calling a [startMention](docs/API_REFERENCE.md#startmention) method on the input ref.

### Mention related events

`react-native-enriched` emits 3 different events that help handling mentions' editing:

- [onStartMention](docs/API_REFERENCE.md#onstartmention) is emitted whenever mention is started in one of the ways from the [previous section](#starting-a-mention) or the user has come back (moved selection) to some unfinished mention they have started. It can be used for opening proper tools you use in the app to edit a mention (e.g. a list for choosing from users or channels that the mention will affect).
- [onChangeMention](docs/API_REFERENCE.md#onchangemention) is emitted whenever user put or removed some characters after a mention indicator. This way you can react to active mention editing by, for example, filtering users in your displayed list based on the typed text.
- [onEndMention](docs/API_REFERENCE.md#onendmention) is emitted whenever user is no longer editing a mention: they might have put a space or changed the cursor position to be no longer near the indicator. You can use it to hide appropriate tools that were used for mention editing.

### Setting a mention

Whenever you feel ready with the currently edited mention (so most likely user chooses something from your additional mention editor), you can complete it by calling [setMention](docs/API_REFERENCE.md#setmention) ref method.

## Inline images

You can insert an image into the input using [setImage](docs/API_REFERENCE.md#setimage) ref method.

The image will be put into a single line in the input and will affect the line's height as well as input's height. Keep in mind, that image will replace currently selected text or insert into the cursor position if there is no text selection.

## Style Detection

All of the above styles can be detected with the use of [onChangeState](docs/API_REFERENCE.md#onchangestate) event payload.

You can find some examples in the [usage section](#usage) or in the example app.

## Other Events

`react-native-enriched` emits a few more events that may be of use:

- [onFocus](docs/API_REFERENCE.md#onfocus) - emits whenever input focuses.
- [onBlur](docs/API_REFERENCE.md) - emits whenever input blurs.
- [onChangeText](docs/API_REFERENCE.md#onchangetext) - returns the input's text anytime it changes.
- [onChangeHtml](docs/API_REFERENCE.md#onchangehtml) - returns HTML string parsed from current input text and styles anytime it would change. As parsing the HTML on each input change is a pretty expensive operation, not assigning the event's callback will speed up iOS input a bit. We are considering adding some API to improve it, see [future plans](#future-plans).
- [onChangeSelection](docs/API_REFERENCE.md#onchangeselection) - returns all the data needed for working with selections (as of now it's mainly useful for [links](#links)).
- [onLinkDetected](docs/API_REFERENCE.md#onlinkdetected) - returns link's detailed info whenever user selection is near one.
- [onMentionDetected](docs/API_REFERENCE.md#onmentiondetected) - returns mention's detailed info whenever user selection is near one.
- [onKeyPress](docs/API_REFERENCE.md#onkeypress) - emits whenever a key is pressed. Follows react-native TextInput's onKeyPress event [spec](https://reactnative.dev/docs/textinput#onkeypress).
- [onPasteImages](docs/API_REFERENCE.md#onpasteimages) - returns an array of images details whenever an image/GIF is pasted into the input.

## Customizing \<EnrichedTextInput /> styles

`react-native-enriched` allows customizing styles of the `<EnrichedTextInput />` component. See [htmlStyle](docs/API_REFERENCE.md#htmlstyle) prop.

## API Reference

See the [API Reference](docs/API_REFERENCE.md) for a detailed overview of all the props, methods, and events available.

## Known limitations

- Only one level of lists is supported. We currently do not support nested lists.
- iOS headings can't have the same `fontSize` in their config as input's `fontSize`. Doing so results in incorrect headings behavior.

## Future Plans

- Creating `EnrichedText` text component that supports our HTML output format with all additional interactions like pressing links or mentions.
- Web library implementation via `react-native-web`.

## Contributing

See the [contributing guide](CONTRIBUTING.md) to learn how to contribute to the repository and the development workflow.

## License

`react-native-enriched` library is licensed under [The MIT License](./LICENSE).

---

Built by [Software Mansion](https://swmansion.com/) and sponsored by [Filament](https://filament.dm/).

[<img width="128" height="69" alt="Software Mansion Logo" src="https://github.com/user-attachments/assets/f0e18471-a7aa-4e80-86ac-87686a86fe56" />](https://swmansion.com/)
&nbsp;&nbsp;&nbsp;
<img width="48" height="48" alt="" src="https://github.com/user-attachments/assets/46c6bf1f-2685-497e-b699-d5a94b2582a3" />
&nbsp;&nbsp;&nbsp;
[<img width="80" height="80" alt="Filament Logo" src="https://github.com/user-attachments/assets/4103ab79-da34-4164-aa5f-dcf08815bf65" />](https://filament.dm/)
