# Web Support (Experimental)

Web support is still experimental. APIs and behavior can change in future releases without a major version bump. Expect breaking changes until the web path is stabilized.

## What works

- Inline marks: bold, italic, underline, strikethrough, inline code
- Headings (h1-h6)
- Blockquote, code block
- Ordered lists, unordered lists, checkbox lists
- Manual links (via `setLink` ref method)
- `getHTML`, `setValue`, selection mapping
- Core callbacks: `onChange`, `onChangeState`, `onFocus`, `onBlur`, `onSelectionChange`

## Unsupported

- **Mentions**: `startMention` and `setMention` are no-ops. Props `mentionIndicators`, `onMentionDetected`, `onStartMention`, `onChangeMention`, and `onEndMention` are ignored. `onChangeState.mention` is always inactive.
- **Images**: `setImage` is a no-op. `onPasteImages` is never called. `onChangeState.image` is always inactive.
- **Automatic link detection**: `linkRegex` is ignored. Links only work when set explicitly via the `setLink` ref method.
- **Submit and keyboard props**: `onSubmitEditing`, `returnKeyType`, `returnKeyLabel`, and `submitBehavior` have no effect.
- **Context menu**: `contextMenuItems` is ignored.
- **Theming props**: `placeholderTextColor`, `cursorColor`, and `selectionColor` are not applied.
- **HTML normalizer flag**: `useHtmlNormalizer` is ignored; paste behavior follows the browser pipeline.
- **RN layout ref methods**: `measure`, `measureInWindow`, `measureLayout`, and `setNativeProps` are no-ops.
- **`EnrichedText`**: The read-only component is not exported on web.
- **`ViewProps`**: Props inherited from `View` beyond the implemented subset are not forwarded.

## HTML sanitization

You are responsible for sanitizing HTML on both input and output. The library does not guarantee safe or clean HTML output. This applies to any HTML you persist, render elsewhere, or accept from untrusted sources (XSS, paste attacks, etc.).
