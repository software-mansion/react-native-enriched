import { test, expect } from '@playwright/test';

import { copyAndPasteBetween } from '../helpers/clipboard';
import {
  getSerializedHtml,
  gotoVisualRegression,
  setEditorHtml,
  setHtmlStyleOverride,
} from '../helpers/visual-regression';
import { toolbarButton } from '../helpers/toolbar';

function h1Inner(serialized: string): string | null {
  const m = serialized.match(/<h1[^>]*>([\s\S]*?)<\/h1>/);
  return m ? m[1] : null;
}

const HTML_STYLE_H1_BOLD_TRUE = '{ "h1": { "bold": true } }';
const HTML_STYLE_H1_BOLD_FALSE = '{ "h1": { "bold": false } }';

test.describe('h1 bold from htmlStyle (h1.bold true)', () => {
  test.beforeEach(async ({ page }) => {
    await gotoVisualRegression(page);
    await setHtmlStyleOverride(page, HTML_STYLE_H1_BOLD_TRUE);
  });

  test('bold toolbar is disabled inside h1 when htmlStyle h1.bold is true', async ({
    page,
  }) => {
    await setEditorHtml(page, '<html><h1>Heading</h1></html>');

    await page.locator('.eti-editor h1').click();

    await expect(toolbarButton(page, 'bold')).toBeDisabled();
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

    await copyAndPasteBetween(
      page.locator('.eti-editor p').first(),
      page.locator('.eti-editor h1')
    );

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
    await gotoVisualRegression(page);
    await setHtmlStyleOverride(page, HTML_STYLE_H1_BOLD_FALSE);
  });

  test('bold toolbar is enabled and can be active inside h1 when htmlStyle h1.bold is false', async ({
    page,
  }) => {
    await setEditorHtml(page, '<html><h1>Heading</h1></html>');

    await page.locator('.eti-editor h1').click();

    const boldBtn = toolbarButton(page, 'bold');
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

    await copyAndPasteBetween(
      page.locator('.eti-editor p').first(),
      page.locator('.eti-editor h1')
    );

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
