# EnrichedText API Reference

> **Web is not yet supported.** `EnrichedText` is only available on iOS and Android.

## Props

### `allowFontScaling`

If `true`, the text respects the system's accessibility font scaling settings.

| Type   | Default Value | Platform     |
| ------ | ------------- | ------------ |
| `bool` | `true`        | iOS, Android |

### `children`

The HTML string to render. Accepts the HTML format produced by `EnrichedTextInput`.

| Type     | Default Value | Platform     |
| -------- | ------------- | ------------ |
| `string` | -             | iOS, Android |

### `style`

Standard React Native `TextStyle` applied to the text.

| Type        | Default Value | Platform     |
| ----------- | ------------- | ------------ |
| `TextStyle` | -             | iOS, Android |

### `htmlStyle`

A prop for customizing styles of HTML elements, including press colors for interactive elements.

| Type                                                   | Default Value | Platform     |
| ------------------------------------------------------ | ------------- | ------------ |
| [`EnrichedTextHtmlStyle`](#enrichedtexthtmlstyle-type) | -             | iOS, Android |

### `useHtmlNormalizer`

If `true`, external HTML (e.g. from Google Docs, Word, web pages) will be normalized before rendering. This converts arbitrary HTML into the canonical tag subset that the enriched parser understands.

| Type   | Default Value | Platform     |
| ------ | ------------- | ------------ |
| `bool` | `false`       | iOS, Android |

### `ellipsizeMode`

How the text should be truncated when `numberOfLines` is set and the text overflows.

- `head` – truncates at the beginning, e.g. `...wxyz`.
- `middle` – truncates in the middle, e.g. `ab...yz`.
- `tail` – truncates at the end, e.g. `abcd...`.
- `clip` – clips the text without inserting an ellipsis.

| Type                                     | Default Value | Platform     |
| ---------------------------------------- | ------------- | ------------ |
| `'head' \| 'middle' \| 'tail' \| 'clip'` | `'tail'`      | iOS, Android |

> [!NOTE]
> On Android, when numberOfLines is set to a value higher than 1, only tail value will work correctly.

### `numberOfLines`

Limits the number of displayed lines. Set to `0` for unlimited lines.

| Type     | Default Value | Platform     |
| -------- | ------------- | ------------ |
| `number` | `0`           | iOS, Android |

### `selectable`

If `true`, the text can be selected by the user (e.g. for copy/paste).

| Type   | Default Value | Platform     |
| ------ | ------------- | ------------ |
| `bool` | `false`       | iOS, Android |

### `selectionColor`

The color of the text selection highlight.

| Type                                           | Default Value  | Platform     |
| ---------------------------------------------- | -------------- | ------------ |
| [`color`](https://reactnative.dev/docs/colors) | system default | iOS, Android |

### `onLinkPress`

Called when the user presses a link element. Receives an `OnLinkPressEvent` containing the link's URL.

```ts
interface OnLinkPressEvent {
  url: string;
}
```

| Type                                | Default Value | Platform     |
| ----------------------------------- | ------------- | ------------ |
| `(event: OnLinkPressEvent) => void` | -             | iOS, Android |

### `onMentionPress`

Called when the user presses a mention element. Receives an `OnMentionPressEvent` with the mention's text, indicator character, and custom attributes.

```ts
interface OnMentionPressEvent {
  text: string;
  indicator: string;
  attributes: Record<string, string>;
}
```

| Type                                   | Default Value | Platform     |
| -------------------------------------- | ------------- | ------------ |
| `(event: OnMentionPressEvent) => void` | -             | iOS, Android |

## EnrichedTextHtmlStyle type

Extends [`HtmlStyle`](API_REFERENCE.md#htmlstyle-type) with additional press-state styling for interactive elements. All properties from `HtmlStyle` are supported except `a` and `mention`, which are replaced by the extended versions below.

```ts
interface EnrichedTextHtmlStyle extends Omit<HtmlStyle, 'a' | 'mention'> {
  a?: {
    color?: ColorValue;
    textDecorationLine?: 'underline' | 'none';
    pressColor?: ColorValue;
  };
  mention?:
    | Record<string, EnrichedTextMentionStyleProperties>
    | EnrichedTextMentionStyleProperties;
}

interface EnrichedTextMentionStyleProperties {
  color?: ColorValue;
  backgroundColor?: ColorValue;
  textDecorationLine?: 'underline' | 'none';
  pressColor?: ColorValue;
  pressBackgroundColor?: ColorValue;
}
```

### a (link)

Inherits all properties from [`HtmlStyle`'s `a`](API_REFERENCE.md#a-link) and adds:

- `pressColor` – the color of the link text while it is being pressed. Takes a [color](https://reactnative.dev/docs/colors) value.

### mention

Inherits all properties from [`HtmlStyle`'s `mention`](API_REFERENCE.md#mention) and adds:

- `pressColor` – the color of the mention text while it is being pressed. Takes a [color](https://reactnative.dev/docs/colors) value.
- `pressBackgroundColor` – the background color of the mention while it is being pressed. Takes a [color](https://reactnative.dev/docs/colors) value.

Same as in `HtmlStyle`, if only a single config is given the style applies to all mention types. To style each indicator separately, pass a record with indicators as keys and configs as values.
