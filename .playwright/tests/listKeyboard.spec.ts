import { test, expect } from '@playwright/test';

import { toolbarButton } from '../helpers/toolbar';
import {
  editorLocator,
  getSerializedHtml,
  gotoVisualRegression,
  setEditorHtml,
} from '../helpers/visual-regression';

function countOpeningTag(html: string, tagName: string): number {
  const re = new RegExp(`<${tagName}[^>]*>`, 'gi');
  return (html.match(re) ?? []).length;
}

const SCREENSHOT_STABILIZE_MS = 200;
const KEY_ACTION_DELAY = 60;

const LIST_VARIANTS = [
  {
    label: 'bullet',
    wrap: (inner: string) => `<html><ul>${inner}</ul></html>`,
    wrapperSelector: '.eti-editor ul',
    toolbarTestId: 'unorderedList',
    listTagName: 'ul',
  },
  {
    label: 'ordered',
    wrap: (inner: string) => `<html><ol>${inner}</ol></html>`,
    wrapperSelector: '.eti-editor ol',
    toolbarTestId: 'orderedList',
    listTagName: 'ol',
  },
  {
    label: 'checkbox',
    wrap: (inner: string) =>
      `<html><ul data-type="checkbox">${inner}</ul></html>`,
    wrapperSelector: '.eti-editor ul[data-type="checkboxList"]',
    toolbarTestId: 'checkboxList',
    listTagName: 'ul',
  },
] as const;

for (const {
  label,
  wrap,
  wrapperSelector,
  toolbarTestId,
  listTagName,
} of LIST_VARIANTS) {
  test.describe(`list keyboard (${label})`, () => {
    test.beforeEach(async ({ page }) => {
      await gotoVisualRegression(page);
    });

    test('Enter extends list', async ({ page }) => {
      const editor = editorLocator(page);
      const wrapper = page.locator(wrapperSelector);
      const items = wrapper.locator('li');

      await setEditorHtml(page, wrap('<li>Line</li>'));

      await editor.click();
      await items.first().click();
      await editor.press('End');

      for (let i = 0; i < 3; i++) {
        await editor.press('Enter', { delay: KEY_ACTION_DELAY });
      }

      await page.waitForTimeout(SCREENSHOT_STABILIZE_MS);
      await expect(editor).toHaveScreenshot(`list-keyboard-enter-${label}.png`);
    });

    test('Enter causes scrolling', async ({ page }) => {
      const editor = editorLocator(page);
      const wrapper = page.locator(wrapperSelector);
      await editor.evaluate((el) => {
        el.style.maxHeight = '120px';
      });
      const items = wrapper.locator('li');

      await setEditorHtml(page, wrap('<li>a</li><li>b</li><li>c</li>'));

      await editor.click();
      await items.last().click();
      await page.keyboard.press('Enter', { delay: KEY_ACTION_DELAY });

      await page.keyboard.type('\n\n\n\n\n', { delay: 10 });

      await page.waitForTimeout(SCREENSHOT_STABILIZE_MS);
      await expect(editor).toHaveScreenshot(
        `list-keyboard-enter-causes-scrolling-${label}.png`
      );
    });

    test('Backspace at line start lifts item then merges backward', async ({
      page,
    }) => {
      const editor = editorLocator(page);
      const wrapper = page.locator(wrapperSelector);
      const lines = wrapper.locator('li');

      await setEditorHtml(page, wrap('<li>first</li><li>second</li>'));

      const secondLine = lines.nth(1);
      await secondLine.click();
      await editor.press('End');
      for (let i = 0; i < 'second'.length; i++) {
        await editor.press('ArrowLeft', { delay: KEY_ACTION_DELAY });
      }

      await editor.press('Backspace', { delay: KEY_ACTION_DELAY });

      await page.waitForTimeout(SCREENSHOT_STABILIZE_MS);
      await expect(editor).toHaveScreenshot(
        `list-keyboard-backspace-after-lift-${label}.png`
      );

      await editor.press('Backspace', { delay: KEY_ACTION_DELAY });

      await page.waitForTimeout(SCREENSHOT_STABILIZE_MS);
      await expect(editor).toHaveScreenshot(
        `list-keyboard-backspace-after-merge-${label}.png`
      );
    });

    test('heading round-trip on middle line keeps a single list in HTML', async ({
      page,
    }) => {
      const editor = editorLocator(page);
      const toolbarBtn = toolbarButton(page, toolbarTestId);
      const wrapper = page.locator(wrapperSelector);
      const h1Btn = toolbarButton(page, 'h1');

      await setEditorHtml(
        page,
        wrap('<li>line1</li><li>line2</li><li>line3</li>')
      );

      await wrapper.locator('li p').nth(1).click();
      await expect(toolbarBtn).toHaveClass(/toolbar-btn--active/);

      await h1Btn.click();

      await expect
        .poll(async () => (await getSerializedHtml(page)).includes('<h1'))
        .toBe(true);

      await toolbarBtn.click();

      await expect
        .poll(async () => {
          const h = await getSerializedHtml(page);
          return countOpeningTag(h, listTagName);
        })
        .toBe(1);

      const out = await getSerializedHtml(page);
      expect(out).toContain('line1');
      expect(out).toContain('line2');
      expect(out).toContain('line3');

      await editor.click();
      await wrapper.locator('li p').first().click();
      await expect(toolbarBtn).toHaveClass(/toolbar-btn--active/);
    });
  });
}
