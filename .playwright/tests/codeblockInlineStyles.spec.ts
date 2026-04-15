import { test, expect, type Page } from '@playwright/test';

const EDITOR_INNER = '[data-testid="visual-regression-editor"] .eti-editor';
const HTML_INPUT = '[data-testid="visual-regression-html-input"]';
const SET_VALUE_BTN = '[data-testid="visual-regression-set-value-button"]';
const EDITOR_HTML_OUTPUT =
  '[data-testid="visual-regression-editor-html-output"]';

/** Opening tags for marks that must not appear in serialized HTML inside codeblock after strip. */
const INLINE_MARK_TAG = /<\s*(b|strong|i|em|u|s|strike|code)\b/i;

async function getSerializedHtml(page: Page) {
  return (await page.locator(EDITOR_HTML_OUTPUT).textContent()) ?? '';
}

/** Serialized inner HTML of the first `<codeblock>...</codeblock>` (for assertions; doc may have other blocks). */
function htmlInsideCodeblock(serialized: string): string {
  const m = serialized.match(/<codeblock[^>]*>([\s\S]*?)<\/codeblock>/i);
  return m ? m[1] : '';
}

const INLINE_TOOLBAR_KEYS = [
  'bold',
  'italic',
  'underline',
  'strikeThrough',
  'inlineCode',
] as const;

async function setEditorHtml(
  page: import('@playwright/test').Page,
  html: string
) {
  await page.fill(HTML_INPUT, html);
  await page.click(SET_VALUE_BTN);
  await page.waitForTimeout(300);
}

test.describe('codeblock inline styles', () => {
  test.beforeEach(async ({ page }) => {
    await page.goto('/visual-regression');
    await page.waitForSelector(EDITOR_INNER);
  });

  test('inline toolbar controls are disabled inside code block', async ({
    page,
  }) => {
    await setEditorHtml(
      page,
      '<html><codeblock><p>Inside code</p></codeblock></html>'
    );

    await page.locator('.eti-editor codeblock p').click();

    for (const key of INLINE_TOOLBAR_KEYS) {
      await expect(
        page.locator(`[data-testid="toolbar-button-${key}"]`)
      ).toBeDisabled();
    }
  });

  test('setValue strips inline styles inside code block', async ({ page }) => {
    await setEditorHtml(
      page,
      '<html><codeblock><p><b>bold</b> <i>italic</i> <u>underline</u> <s>strike</s> <code>inline</code></p></codeblock></html>'
    );

    const html = await getSerializedHtml(page);
    expect(htmlInsideCodeblock(html)).not.toMatch(INLINE_MARK_TAG);

    await expect(page.locator(EDITOR_INNER)).toHaveScreenshot(
      'codeblock-inline-styles-setvalue-stripped.png'
    );
  });

  test('paste into code block strips copied inline styles', async ({
    page,
  }) => {
    await setEditorHtml(
      page,
      '<html><p><b>pasteMe</b></p><codeblock><p>placeholder</p></codeblock></html>'
    );

    const firstParagraph = page.locator('.eti-editor p').first();
    await firstParagraph.click();
    await firstParagraph.click({ clickCount: 3 });
    await page.keyboard.press('ControlOrMeta+C');

    const codeblockP = page.locator('.eti-editor codeblock p');
    await codeblockP.click();
    await codeblockP.click({ clickCount: 3 });
    await page.keyboard.press('ControlOrMeta+V');

    await page.waitForTimeout(300);

    const htmlAfterPaste = await getSerializedHtml(page);
    expect(htmlInsideCodeblock(htmlAfterPaste)).not.toMatch(INLINE_MARK_TAG);

    await expect(page.locator(EDITOR_INNER)).toHaveScreenshot(
      'codeblock-inline-styles-paste-stripped.png'
    );
  });
});
