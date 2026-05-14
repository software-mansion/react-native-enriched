# Web Support (Experimental)

Web support is still experimental. APIs and behavior can change in future releases without a major version bump. Expect breaking changes until the web path is stabilized.

## What works

- Inline marks: bold, italic, underline, strikethrough, inline code
- Headings (h1-h6)
- Blockquote, code block
- Ordered lists, unordered lists, checkbox lists
- Images(via `setImage` ref method)
- Manual links (via `setLink` ref method)
- Mentions
- `getHTML`, `setValue`, selection mapping
- Core callbacks: `onChange`, `onChangeState`, `onFocus`, `onBlur`, `onSelectionChange`
- Input theming via `placeholderTextColor`, `cursorColor` and `selectionColor` props
- Keyboard shortcuts for formatting 

## Keyboard shortcuts

| Action | Mac | Windows/Linux |
| --- | --- | --- |
| Bold | ⌘ B | Ctrl+B |
| Italic | ⌘ I | Ctrl+I |
| Underline | ⌘ U | Ctrl+U |
| Strikethrough | ⌘ Shift+X | Ctrl+Shift+X |
| Inline code | ⌘ Shift+C | Ctrl+Shift+C |
| Code block | ⌘ Alt Shift+C | Ctrl+Alt+Shift+C |
| Normal paragraph | ⌘ Alt+0 | Ctrl+Alt+0 |
| Heading `n` (h1–h6) | ⌘ Alt+1 … ⌘ Alt+6 | Ctrl+Alt+1 … Ctrl+Alt+6 |
| Numbered list | ⌘ Shift+7 | Ctrl+Shift+7 |
| Bulleted list | ⌘ Shift+8 | Ctrl+Shift+8 |
| Checkbox list | ⌘ Shift+9 | Ctrl+Shift+9 |
| Paste plain text | ⌘ Shift+V | Ctrl+Shift+V |


## Unsupported

- **Pasting images**: `onPasteImages` is never called.
- **Automatic link detection**: `linkRegex` is ignored. Links only work when set explicitly via the `setLink` ref method.
- **Submit and keyboard props**: `onSubmitEditing`, `returnKeyType`, `returnKeyLabel`, and `submitBehavior` have no effect.
- **Context menu**: `contextMenuItems` is ignored.
- **HTML normalizer flag**: `useHtmlNormalizer` is ignored; default ⌘/Ctrl+V paste follows the browser pipeline (rich paste still parses HTML unless blocked elsewhere).
- **RN layout ref methods**: `measure`, `measureInWindow`, `measureLayout`, and `setNativeProps` are no-ops.
- **`EnrichedText`**: The read-only component is not exported on web.
- **`ViewProps`**: Props inherited from `View` beyond the implemented subset are not forwarded.

## HTML sanitization

You are responsible for sanitizing HTML on both input and output. The library does not guarantee safe or clean HTML output. This applies to any HTML you persist, render elsewhere, or accept from untrusted sources (XSS, paste attacks, etc.).
