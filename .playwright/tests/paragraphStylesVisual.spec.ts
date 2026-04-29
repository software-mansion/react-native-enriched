import { test, expect } from '@playwright/test';

import {
  editorLocator,
  gotoVisualRegression,
  setEditorHtml,
} from '../helpers/visual-regression';

test.describe('paragraph styles visual', () => {
  test.beforeEach(async ({ page }) => {
    await gotoVisualRegression(page);
  });

  test('headings h1–h6 display correctly', async ({ page }) => {
    const html =
      '<html><h1>H1</h1><h2>H2</h2><h3>H3</h3><h4>H4</h4><h5>H5</h5><h6>H6</h6></html>';
    await setEditorHtml(page, html);

    const editor = editorLocator(page);
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

    const editor = editorLocator(page);
    await expect(editor).toContainText('Blockquote smoke');

    await expect(editor).toHaveScreenshot(
      'paragraph-styles-visual-blockquote.png'
    );
  });

  test('codeblock displays correctly', async ({ page }) => {
    const html = '<html><codeblock><p>Codeblock smoke</p></codeblock></html>';
    await setEditorHtml(page, html);

    const editor = editorLocator(page);
    await expect(editor).toContainText('Codeblock smoke');

    await expect(editor).toHaveScreenshot(
      'paragraph-styles-visual-codeblock.png'
    );
  });

  test('unordered list displays correctly', async ({ page }) => {
    const html = '<html><ul><li>Alpha</li><li>Beta</li></ul></html>';
    await setEditorHtml(page, html);

    const editor = editorLocator(page);
    await expect(editor).toContainText('Alpha');
    await expect(editor).toContainText('Beta');

    await expect(editor).toHaveScreenshot(
      'paragraph-styles-visual-unordered-list.png'
    );
  });

  test('ordered list displays correctly', async ({ page }) => {
    const html = '<html><ol><li>One</li><li>Two</li></ol></html>';
    await setEditorHtml(page, html);

    const editor = editorLocator(page);
    await expect(editor).toContainText('One');
    await expect(editor).toContainText('Two');

    await expect(editor).toHaveScreenshot(
      'paragraph-styles-visual-ordered-list.png'
    );
  });

  test('checkbox list displays correctly', async ({ page }) => {
    const html =
      '<html><ul data-type="checkbox"><li>a</li><li checked>b</li></ul></html>';
    await setEditorHtml(page, html);

    const editor = editorLocator(page);
    await expect(editor).toContainText('a');
    await expect(editor).toContainText('b');

    await expect(editor).toHaveScreenshot(
      'paragraph-styles-visual-checkbox-list.png'
    );
  });
});
