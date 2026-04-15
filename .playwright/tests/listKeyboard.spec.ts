import { test, expect } from '@playwright/test';

import { toolbarButton } from '../helpers/toolbar';
import {
  editorLocator,
  getSerializedHtml,
  gotoVisualRegression,
  setEditorHtml,
} from '../helpers/visual-regression';

function countOpeningTag(html: string, tagName: string): number {
  const re = new RegExp(`<${tagName}(?:\\s[^>]*)?>`, 'gi');
  return (html.match(re) ?? []).length;
}

const LIST_VARIANTS = [
  {
    label: 'bullet',
    wrap: (inner: string) => `<html><ul>${inner}</ul></html>`,
    wrapperSelector: '.eti-editor ul',
    toolbarTestId: 'unorderedList' as const,
    listTagForCount: 'bullet' as const,
  },
  {
    label: 'ordered',
    wrap: (inner: string) => `<html><ol>${inner}</ol></html>`,
    wrapperSelector: '.eti-editor ol',
    toolbarTestId: 'orderedList' as const,
    listTagForCount: 'ol' as const,
  },
] as const;

for (const {
  label,
  wrap,
  wrapperSelector,
  toolbarTestId,
  listTagForCount,
} of LIST_VARIANTS) {
  test.describe(`list keyboard (${label})`, () => {
    test.beforeEach(async ({ page }) => {
      await gotoVisualRegression(page);
    });

    test('Enter extends list', async ({ page }) => {
      const editor = editorLocator(page);
      const wrapper = page.locator(wrapperSelector);
      const items = wrapper.locator('li');

      await setEditorHtml(page, wrap('<li><p>Line</p></li>'));

      await editor.click();
      await items.first().click();
      await editor.press('End');

      const enters = 3;
      for (let i = 0; i < enters; i++) {
        await editor.press('Enter', { delay: 60 });
      }

      await page.waitForTimeout(200);
      await expect(editor).toHaveScreenshot(`list-keyboard-enter-${label}.png`);
    });

    test('Backspace at line start lifts item then merges backward', async ({
      page,
    }) => {
      const editor = editorLocator(page);
      const wrapper = page.locator(wrapperSelector);
      const lines = wrapper.locator('li');

      await setEditorHtml(
        page,
        wrap('<li><p>first</p></li><li><p>second</p></li>')
      );

      const secondLine = lines.nth(1);
      await secondLine.click();
      await editor.press('End');
      for (let i = 0; i < 'second'.length; i++) {
        await editor.press('ArrowLeft', { delay: 60 });
      }

      await editor.press('Backspace', { delay: 60 });

      await page.waitForTimeout(200);
      await expect(editor).toHaveScreenshot(
        `list-keyboard-backspace-after-lift-${label}.png`
      );

      await editor.press('Backspace', { delay: 60 });

      await page.waitForTimeout(200);
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
        wrap('<li><p>line1</p></li><li><p>line2</p></li><li><p>line3</p></li>')
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
          if (listTagForCount === 'bullet') {
            return countOpeningTag(h, 'ul');
          }
          return countOpeningTag(h, 'ol');
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
