import { test, expect } from '@playwright/test';

import {
  editorLocator,
  getSerializedHtml,
  gotoVisualRegression,
  setEditorHtml,
} from '../helpers/visual-regression';
import { toolbarButton } from '../helpers/toolbar';

function countOpeningTag(html: string, tagName: string): number {
  const re = new RegExp(`<${tagName}(?:\\s[^>]*)?>`, 'gi');
  return (html.match(re) ?? []).length;
}

const WRAPPED_BLOCKS = [
  {
    label: 'blockquote',
    tag: 'blockquote',
    wrapperSelector: '.eti-editor blockquote',
    toolbarTestId: 'blockQuote',
  },
  {
    label: 'codeblock',
    tag: 'codeblock',
    wrapperSelector: '.eti-editor codeblock',
    toolbarTestId: 'codeBlock',
  },
] as const;

for (const { label, tag, wrapperSelector, toolbarTestId } of WRAPPED_BLOCKS) {
  test.describe(`wrapped block keyboard (${label})`, () => {
    test.beforeEach(async ({ page }) => {
      await gotoVisualRegression(page);
    });

    test('Enter splits inside wrapper and keeps block active', async ({
      page,
    }) => {
      const editor = editorLocator(page);
      const wrapper = page.locator(wrapperSelector);
      const paragraphs = wrapper.locator('p');

      await setEditorHtml(page, `<html><${tag}><p>Line</p></${tag}></html>`);

      await editor.click();
      await paragraphs.first().click();
      await editor.press('End');

      const enters = 3;
      for (let i = 0; i < enters; i++) {
        await editor.press('Enter', { delay: 60 });
      }

      await page.waitForTimeout(200);
      await expect(editor).toHaveScreenshot(
        `wrapped-block-keyboard-enter-${label}.png`
      );
    });

    test('Backspace at line start lifts paragraph then merges backward', async ({
      page,
    }) => {
      const editor = editorLocator(page);
      const wrapper = page.locator(wrapperSelector);
      const paragraphsInWrapper = wrapper.locator('p');

      await setEditorHtml(
        page,
        `<html><${tag}><p>first</p><p>second</p></${tag}></html>`
      );

      const secondP = paragraphsInWrapper.nth(1);
      await secondP.click();
      await editor.press('End');
      for (let i = 0; i < 'second'.length; i++) {
        await editor.press('ArrowLeft', { delay: 60 });
      }

      await editor.press('Backspace', { delay: 60 });

      await page.waitForTimeout(200);
      await expect(editor).toHaveScreenshot(
        `wrapped-block-keyboard-backspace-after-lift-${label}.png`
      );

      await editor.press('Backspace', { delay: 60 });

      await page.waitForTimeout(200);
      await expect(editor).toHaveScreenshot(
        `wrapped-block-keyboard-backspace-after-merge-${label}.png`
      );
    });

    test('heading round-trip on middle line merges to single wrapper in HTML', async ({
      page,
    }) => {
      const editor = editorLocator(page);
      const toolbarBtn = toolbarButton(page, toolbarTestId);
      const wrapper = page.locator(wrapperSelector);
      const h1Btn = toolbarButton(page, 'h1');

      await setEditorHtml(
        page,
        `<html><${tag}><p>line1</p><p>line2</p><p>line3</p></${tag}></html>`
      );

      await wrapper.locator('p').nth(1).click();
      await expect(toolbarBtn).toHaveClass(/toolbar-btn--active/);

      await h1Btn.click();

      await expect
        .poll(async () => (await getSerializedHtml(page)).includes('<h1'))
        .toBe(true);

      await toolbarBtn.click();

      await expect
        .poll(async () => countOpeningTag(await getSerializedHtml(page), tag))
        .toBe(1);

      const out = await getSerializedHtml(page);
      expect(out).toContain('line1');
      expect(out).toContain('line2');
      expect(out).toContain('line3');

      await editor.click();
      await wrapper.locator('p').first().click();
      await expect(toolbarBtn).toHaveClass(/toolbar-btn--active/);
    });
  });
}
