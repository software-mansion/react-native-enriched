import { test, expect } from '@playwright/test';

import {
  editorLocator,
  getSerializedHtml,
  gotoVisualRegression,
  setEditorHtml,
} from '../helpers/visual-regression';

function hasNestedListInsideLi(html: string): boolean {
  return /<li[^>]*>[\s\S]*?<(?:ul|ol)\b/i.test(html);
}

const CASES = [
  {
    name: 'nested ul under bullet ul',
    html: '<html><ul><li>item<ul><li>nested</li></ul></li></ul></html>',
    markers: ['item', 'nested'] as const,
    screenshot: 'list-nested-html-ul-in-ul.png',
    expectNestedListInsideLi: false,
  },
  {
    name: 'nested ol under bullet ul',
    html: '<html><ul><li>outer<ol><li>nested</li></ol></li></ul></html>',
    markers: ['outer', 'nested'] as const,
    screenshot: 'list-nested-html-ol-in-ul.png',
    expectNestedListInsideLi: true,
  },
  {
    name: 'nested ul under ordered ol',
    html: '<html><ol><li>outer<ul><li>nested</li></ul></li></ol></html>',
    markers: ['outer', 'nested'] as const,
    screenshot: 'list-nested-html-ul-in-ol.png',
    expectNestedListInsideLi: true,
  },
] as const;

test.describe('list nested html', () => {
  test.beforeEach(async ({ page }) => {
    await gotoVisualRegression(page);
  });

  for (const {
    name,
    html,
    markers,
    screenshot,
    expectNestedListInsideLi: expectNested,
  } of CASES) {
    test(name, async ({ page }) => {
      await setEditorHtml(page, html);

      await expect
        .poll(async () => {
          const s = await getSerializedHtml(page);
          return markers.every((m) => s.includes(m));
        })
        .toBe(true);

      const out = await getSerializedHtml(page);
      for (const m of markers) {
        expect(out).toContain(m);
      }
      expect(hasNestedListInsideLi(out)).toBe(expectNested);

      const editor = editorLocator(page);
      await expect(editor).toHaveScreenshot(screenshot);
    });
  }
});
