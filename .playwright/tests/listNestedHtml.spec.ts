import { test, expect } from '@playwright/test';

import {
  editorLocator,
  gotoVisualRegression,
  setEditorHtml,
} from '../helpers/visual-regression';

const CASES = [
  {
    name: 'nested ul under bullet ul',
    html: '<html><ul><li>item<ul><li>nested</li></ul></li></ul></html>',
    markers: ['item', 'nested'] as const,
    screenshot: 'list-nested-html-ul-in-ul.png',
  },
  {
    name: 'nested ol under bullet ul',
    html: '<html><ul><li>outer<ol><li>nested</li></ol></li></ul></html>',
    markers: ['outer', 'nested'] as const,
    screenshot: 'list-nested-html-ol-in-ul.png',
  },
  {
    name: 'nested ul under ordered ol',
    html: '<html><ol><li>outer<ul><li>nested</li></ul></li></ol></html>',
    markers: ['outer', 'nested'] as const,
    screenshot: 'list-nested-html-ul-in-ol.png',
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
