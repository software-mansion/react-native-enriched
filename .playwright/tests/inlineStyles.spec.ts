import { test, expect } from '@playwright/test';

const EDITOR = '[data-testid="visual-regression-editor"]';
const EDITOR_INNER = `${EDITOR} .eti-editor`;
const HTML_INPUT = '[data-testid="visual-regression-html-input"]';
const SET_VALUE_BTN = '[data-testid="visual-regression-set-value-button"]';

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
  await page.goto('/visual-regression');
  await page.waitForSelector(EDITOR_INNER);

  await page.fill(HTML_INPUT, ALL_INLINE_STYLES);
  await page.click(SET_VALUE_BTN);
  await page.waitForTimeout(300);

  await expect(page.locator(EDITOR_INNER)).toHaveScreenshot(
    'inline_styles.png'
  );
});
