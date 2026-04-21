import { test, expect } from '@playwright/test';

import {
  editorLocator,
  gotoVisualRegression,
  setEditorHtml,
} from '../helpers/visual-regression';

const ALL_INLINE_STYLES = [
  '<html>',
  '<p>Plain text</p>',
  '<p><b>Bold text</b></p>',
  '<p><u>Underlined text</u></p>',
  '<p><s>Strikethrough text</s></p>',
  '<p><code>inline code</code></p>',
  '<p><code><b><i><u><s>combined</s></u></i></b></code></p>',
  '</html>',
].join('');

test('inline styles visual regression', async ({ page }) => {
  await gotoVisualRegression(page);
  await setEditorHtml(page, ALL_INLINE_STYLES);

  await expect(editorLocator(page)).toHaveScreenshot('inline-styles.png');
});
