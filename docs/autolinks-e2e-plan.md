# Autolink E2E tests (Playwright + TestLinks)

## Checkpoint workflow

1. Checkpoint commit documents this approach (`docs: checkpoint autolink e2e plan`).
2. Implement harness + tests (see below).
3. On failure: `git reset --hard <checkpoint-sha>` and retry from this file.

## Harness (`apps/example-web/src/testScreens/TestLinks.tsx`)

Pass `linkRegex` into `EnrichedTextInput`:

| Mode | Prop |
|------|------|
| Default | `undefined` |
| Disabled | `null` |
| Custom | `new RegExp(pattern, flags)` |

**Test IDs**

- `test-links-link-regex-mode` — `<select>`: `default` | `disabled` | `custom`
- `test-links-link-regex-pattern` — pattern string (custom only)
- `test-links-link-regex-ignore-case` — checkbox → `i` flag
- `test-links-link-regex-apply` — apply to editor prop
- `test-links-link-regex-error` — inline parse error text (empty when valid)

Invalid regex must not crash the screen.

## Playwright (`.playwright/tests/testLinks.spec.ts`)

Reuse `gotoTestLinks`, `getTestLinksSerializedHtml`, `sel.editorInner`.

| Case | Action | Assert |
|------|--------|--------|
| Typing (default) | Default mode, type URL-like text in editor | Serialized HTML contains expected `<a href="...">` |
| Typing (custom) | Custom pattern + apply, type matching token | Anchor wraps matched text |
| Paste | Clipboard write + paste into editor | Same style of anchor assertion |
| Disabled | Disabled mode, type/paste URL-like text | No new autolink `<a href=` |

Autolinks do not serialize `data-auto`; assert `href` and link text only.

**Clipboard**: `.playwright/helpers/clipboard.ts` — `writeClipboardAndPaste(locator, text)` (or fallback copy-from-textarea pattern if clipboard is flaky).

## Optional follow-up

Update `docs/WEB.md` if it still claims `linkRegex` is ignored on web.
