import { test, expect } from '@playwright/test';

import {
  getSerializedHtml,
  gotoVisualRegression,
  setEditorHtml,
} from '../helpers/visual-regression';

test.setTimeout(90_000);

test('link mark round-trips in serialized HTML', async ({ page }) => {
  await gotoVisualRegression(page);
  await setEditorHtml(
    page,
    '<html><p><a href="https://example.com">Example</a></p></html>'
  );

  await expect
    .poll(async () => getSerializedHtml(page))
    .toContain('https://example.com');
  await expect
    .poll(async () => getSerializedHtml(page))
    .toMatch(/<a[^>]*href=/i);
});
