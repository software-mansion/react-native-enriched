import { test, expect } from '@playwright/test';

const EDITOR = '[data-testid="visual-regression-editor"]';
const EDITOR_INNER = `${EDITOR} .eti-editor`;
const HTML_INPUT = '[data-testid="visual-regression-html-input"]';
const SET_VALUE_BTN = '[data-testid="visual-regression-set-value-button"]';

async function setEditorHtml(
  page: import('@playwright/test').Page,
  html: string
) {
  await page.fill(HTML_INPUT, html);
  await page.click(SET_VALUE_BTN);
  await page.waitForTimeout(300);
}

test.describe('paragraph styles visual', () => {
  test.beforeEach(async ({ page }) => {
    await page.goto('/visual-regression');
    await page.waitForSelector(EDITOR_INNER);
  });

  test('headings h1–h6 display correctly', async ({ page }) => {
    const html =
      '<html><h1>H1</h1><h2>H2</h2><h3>H3</h3><h4>H4</h4><h5>H5</h5><h6>H6</h6></html>';
    await setEditorHtml(page, html);

    const editor = page.locator(EDITOR_INNER);
    await expect(editor).toContainText('H1');
    await expect(editor).toContainText('H6');

    await expect(editor).toHaveScreenshot(
      'paragraph-styles-visual-headings.png'
    );
  });

  test('blockquote displays correctly', async ({ page }) => {
    const html =
      '<html><blockquote><p>Blockquote smoke</p></blockquote></html>';
    await setEditorHtml(page, html);

    const editor = page.locator(EDITOR_INNER);
    await expect(editor).toContainText('Blockquote smoke');

    await expect(editor).toHaveScreenshot(
      'paragraph-styles-visual-blockquote.png'
    );
  });

  test('codeblock displays correctly', async ({ page }) => {
    const html = '<html><codeblock><p>Codeblock smoke</p></codeblock></html>';
    await setEditorHtml(page, html);

    const editor = page.locator(EDITOR_INNER);
    await expect(editor).toContainText('Codeblock smoke');

    await expect(editor).toHaveScreenshot(
      'paragraph-styles-visual-codeblock.png'
    );
  });
});
