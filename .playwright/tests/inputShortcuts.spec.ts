import { test, expect, type Page } from '@playwright/test';

import {
  editorLocator,
  getSerializedHtml,
  gotoVisualRegression,
  setEditorHtml,
} from '../helpers/visual-regression';

const TYPE_SHORTCUT_DELAY_MS = 80;

async function typeShortcut(page: Page, text: string) {
  const editor = editorLocator(page);
  await editor.click();
  await expect(
    editor.locator('[contenteditable="true"]').first()
  ).toBeFocused();

  await editor.pressSequentially(text, { delay: TYPE_SHORTCUT_DELAY_MS });
}

test.describe('list input shortcuts', () => {
  test.beforeEach(async ({ page }) => {
    await gotoVisualRegression(page);
  });

  test('unordered list: type - and space in empty editor', async ({ page }) => {
    await setEditorHtml(page, '<html><p></p></html>');
    await typeShortcut(page, '- ');

    await expect
      .poll(async () => {
        const html = await getSerializedHtml(page);
        return /<ul/i.test(html) && /<li/i.test(html);
      })
      .toBe(true);
  });

  test('ordered list: type 1. and space in empty editor', async ({ page }) => {
    await setEditorHtml(page, '<html><p></p></html>');
    await typeShortcut(page, '1. ');

    await expect
      .poll(async () => {
        const html = await getSerializedHtml(page);
        return /<ol/i.test(html) && /<li/i.test(html);
      })
      .toBe(true);
  });
});
