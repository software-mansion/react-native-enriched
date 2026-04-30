import { test, expect } from '@playwright/test';

import {
  editorLocator,
  gotoVisualRegression,
  setEditorHtml,
} from '../helpers/visual-regression';

const CASES = [
  {
    name: 'ul under ul',
    html: '<html><ul><li>item<ul><li>nested</li></ul></li></ul></html>',
    markers: ['item', 'nested'],
    screenshot: 'list-nested-html-ul-in-ul.png',
  },
  {
    name: 'ol under ul',
    html: '<html><ul><li>outer<ol><li>nested</li></ol></li></ul></html>',
    markers: ['outer', 'nested'],
    screenshot: 'list-nested-html-ol-in-ul.png',
  },
  {
    name: 'ul under ol',
    html: '<html><ol><li>outer<ul><li>nested</li></ul></li></ol></html>',
    markers: ['outer', 'nested'],
    screenshot: 'list-nested-html-ul-in-ol.png',
  },
  {
    name: 'triple nested ul',
    html: '<html><ul><li>outer<ul><li>nested<ul><li>deep</li></ul></li></ul></ul></html>',
    markers: ['outer', 'nested', 'deep'],
    screenshot: 'list-nested-html-triple-nested-ul.png',
  },
] as const;

test.describe('list nested html', () => {
  test.beforeEach(async ({ page }) => {
    await gotoVisualRegression(page);
  });

  for (const { name, html, markers, screenshot } of CASES) {
    test(name, async ({ page }) => {
      await setEditorHtml(page, html);

      const editor = editorLocator(page);
      for (const m of markers) {
        await expect(editor).toContainText(m);
      }

      await expect(editor).toHaveScreenshot(screenshot);
    });
  }
});
