import { test, expect, type Page } from '@playwright/test';

import {
  focusEnrichedEditable,
  getSerializedHtml,
  gotoVisualRegression,
  setEditorHtml,
} from '../helpers/visual-regression';

const TYPE_SHORTCUT_DELAY_MS = 80;

async function typeShortcut(page: Page, text: string) {
  const editor = await focusEnrichedEditable(page);
  await editor.pressSequentially(text, { delay: TYPE_SHORTCUT_DELAY_MS });
}

test.describe('keyboard shortcuts (Slack/Docs chords)', () => {
  test.beforeEach(async ({ context, page }) => {
    await context.grantPermissions(['clipboard-read', 'clipboard-write']);
    await gotoVisualRegression(page);
  });

  test('bold: Cmd/Ctrl+B wraps selection', async ({ page }) => {
    await setEditorHtml(page, '<html><p>hi</p></html>');
    await focusEnrichedEditable(page);
    await page.keyboard.press('ControlOrMeta+a');
    await page.keyboard.press('ControlOrMeta+KeyB');
    await expect.poll(async () => getSerializedHtml(page)).toMatch(/<b[\s>]/i);
  });

  test('italic: Cmd/Ctrl+I wraps selection', async ({ page }) => {
    await setEditorHtml(page, '<html><p>hi</p></html>');
    await focusEnrichedEditable(page);
    await page.keyboard.press('ControlOrMeta+a');
    await page.keyboard.press('ControlOrMeta+KeyI');
    await expect.poll(async () => getSerializedHtml(page)).toMatch(/<i[\s>]/i);
  });

  test('heading: Cmd/Ctrl+Alt+Digit2 sets h2', async ({ page }) => {
    await setEditorHtml(page, '<html><p>x</p></html>');
    await focusEnrichedEditable(page);
    await page.keyboard.press('ControlOrMeta+Alt+Digit2');
    await expect.poll(async () => getSerializedHtml(page)).toMatch(/<h2[\s>]/i);
  });

  test('bulleted list: Cmd/Ctrl+Shift+Digit8', async ({ page }) => {
    await setEditorHtml(page, '<html><p></p></html>');
    await focusEnrichedEditable(page);
    await page.keyboard.press('ControlOrMeta+Shift+Digit8');
    await expect
      .poll(async () => {
        const html = await getSerializedHtml(page);
        return /<ul/i.test(html) && /<li/i.test(html);
      })
      .toBe(true);
  });

  test('paste plain: Cmd/Ctrl+Shift+V inserts text/plain only', async ({
    page,
  }) => {
    await setEditorHtml(page, '<html><p></p></html>');
    await focusEnrichedEditable(page);

    await page.evaluate(async () => {
      await navigator.clipboard.write([
        new ClipboardItem({
          'text/plain': new Blob(['PLAIN_PASTE'], { type: 'text/plain' }),
          'text/html': new Blob(['<strong>HTML_STRONG</strong>'], {
            type: 'text/html',
          }),
        }),
      ]);
    });

    await page.keyboard.press('ControlOrMeta+Shift+KeyV');

    await expect
      .poll(async () => getSerializedHtml(page))
      .toMatch(/PLAIN_PASTE/);

    const html = await getSerializedHtml(page);
    expect(html).not.toMatch(/HTML_STRONG/);
    expect(html).not.toMatch(/<strong/i);
  });
});

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
