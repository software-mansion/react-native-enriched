import { test, expect, type Page } from '@playwright/test';

const EDITOR_INNER = '[data-testid="visual-regression-editor"] .eti-editor';
const HTML_INPUT = '[data-testid="visual-regression-html-input"]';
const SET_VALUE_BTN = '[data-testid="visual-regression-set-value-button"]';
const EDITOR_HTML_OUTPUT =
  '[data-testid="visual-regression-editor-html-output"]';
const HTML_STYLE_OVERRIDE =
  '[data-testid="visual-regression-html-style-override"]';

const BOLD_TOOLBAR = '[data-testid="toolbar-button-bold"]';

/** Merged into VisualRegression default htmlStyle — only `h1.bold` is varied in these tests. */
const HTML_STYLE_H1_BOLD_TRUE = '{ "h1": { "bold": true } }';
const HTML_STYLE_H1_BOLD_FALSE = '{ "h1": { "bold": false } }';

/** Inner HTML of the first `<h1>...</h1>` (attributes on the open tag allowed). */
function h1Inner(serialized: string): string | null {
  const m = serialized.match(/<h1[^>]*>([\s\S]*?)<\/h1>/);
  return m ? m[1] : null;
}

async function getSerializedHtml(page: import('@playwright/test').Page) {
  return (await page.locator(EDITOR_HTML_OUTPUT).textContent()) ?? '';
}

async function setEditorHtml(page: Page, html: string) {
  await page.fill(HTML_INPUT, html);
  await page.click(SET_VALUE_BTN);
  await expect
    .poll(async () => {
      const t = await getSerializedHtml(page);
      return t.startsWith('<html>') && t.length > 0;
    })
    .toBe(true);
}

async function setHtmlStyleOverride(page: Page, json: string) {
  await page.fill(HTML_STYLE_OVERRIDE, json);
}

test.describe('h1 bold from htmlStyle (h1.bold true)', () => {
  test.beforeEach(async ({ page }) => {
    await page.goto('/visual-regression');
    await page.waitForSelector(EDITOR_INNER);
    await setHtmlStyleOverride(page, HTML_STYLE_H1_BOLD_TRUE);
  });

  test('bold toolbar is disabled inside h1 when htmlStyle h1.bold is true', async ({
    page,
  }) => {
    await setEditorHtml(page, '<html><h1>Heading</h1></html>');

    await page.locator('.eti-editor h1').click();

    await expect(page.locator(BOLD_TOOLBAR)).toBeDisabled();
  });

  test('setValue strips redundant <b> inside h1', async ({ page }) => {
    await setEditorHtml(page, '<html><h1><b>Hello</b></h1></html>');

    const inner = h1Inner(await getSerializedHtml(page));
    expect(inner).not.toBeNull();
    expect(inner).not.toContain('<b>');
    expect(inner).toContain('Hello');
  });

  test('paste into h1 strips copied bold mark', async ({ page }) => {
    await setEditorHtml(
      page,
      '<html><p><b>pasteMe</b></p><h1>placeholder</h1></html>'
    );

    await page.locator('.eti-editor p').first().click();
    await page.locator('.eti-editor p').first().click({ clickCount: 3 });
    await page.keyboard.press('ControlOrMeta+C');

    await page.locator('.eti-editor h1').click();
    await page.locator('.eti-editor h1').click({ clickCount: 3 });
    await page.keyboard.press('ControlOrMeta+V');

    await expect
      .poll(async () => {
        const inner = h1Inner(await getSerializedHtml(page));
        return inner?.includes('pasteMe') ?? false;
      })
      .toBe(true);

    const inner = h1Inner(await getSerializedHtml(page));
    expect(inner).not.toBeNull();
    expect(inner).not.toContain('<b>');
    expect(inner).toContain('pasteMe');
  });
});

test.describe('h1 bold from htmlStyle (h1.bold false)', () => {
  test.beforeEach(async ({ page }) => {
    await page.goto('/visual-regression');
    await page.waitForSelector(EDITOR_INNER);
    await setHtmlStyleOverride(page, HTML_STYLE_H1_BOLD_FALSE);
  });

  test('bold toolbar is enabled and can be active inside h1 when htmlStyle h1.bold is false', async ({
    page,
  }) => {
    await setEditorHtml(page, '<html><h1>Heading</h1></html>');

    await page.locator('.eti-editor h1').click();

    const boldBtn = page.locator(BOLD_TOOLBAR);
    await expect(boldBtn).toBeEnabled();
    await boldBtn.click();
    await expect(boldBtn).toHaveClass(/toolbar-btn--active/);
  });

  test('setValue keeps <b> inside h1 when htmlStyle h1.bold is false', async ({
    page,
  }) => {
    await setEditorHtml(page, '<html><h1><b>Hello</b></h1></html>');

    const inner = h1Inner(await getSerializedHtml(page));
    expect(inner).not.toBeNull();
    expect(inner).toContain('<b>');
    expect(inner).toContain('Hello');
  });

  test('paste into h1 keeps copied bold mark when htmlStyle h1.bold is false', async ({
    page,
  }) => {
    await setEditorHtml(
      page,
      '<html><p><b>pasteMe</b></p><h1>placeholder</h1></html>'
    );

    await page.locator('.eti-editor p').first().click();
    await page.locator('.eti-editor p').first().click({ clickCount: 3 });
    await page.keyboard.press('ControlOrMeta+C');

    await page.locator('.eti-editor h1').click();
    await page.locator('.eti-editor h1').click({ clickCount: 3 });
    await page.keyboard.press('ControlOrMeta+V');

    await expect
      .poll(async () => {
        const inner = h1Inner(await getSerializedHtml(page));
        return inner?.includes('pasteMe') ?? false;
      })
      .toBe(true);

    const inner = h1Inner(await getSerializedHtml(page));
    expect(inner).not.toBeNull();
    expect(inner).toContain('<b>');
    expect(inner).toContain('pasteMe');
  });
});
