import { test, expect } from '@playwright/test';

import {
  editorLocator,
  getSerializedHtml,
  gotoVisualRegression,
  setEditorHtml,
} from '../helpers/visual-regression';

const CASES: { name: string; input: string; expected: string }[] = [
  {
    name: 'plain paragraph (no checkbox list)',
    input: '<html><p>hello</p></html>',
    expected: '<html><p>hello</p></html>',
  },
  {
    name: 'checkbox list all unchecked',
    input:
      '<html><ul data-type="checkbox"><li>one</li><li>two</li></ul></html>',
    expected:
      '<html><ul data-type="checkbox"><li>one</li><li>two</li></ul></html>',
  },
  {
    name: 'checkbox list with checked item',
    input:
      '<html><ul data-type="checkbox"><li>one</li><li checked>two</li></ul></html>',
    expected:
      '<html><ul data-type="checkbox"><li>one</li><li checked>two</li></ul></html>',
  },
];

test.describe('checkbox list (web)', () => {
  test.beforeEach(async ({ page }) => {
    await gotoVisualRegression(page);
  });

  for (const { name, input, expected } of CASES) {
    test(name, async ({ page }) => {
      await setEditorHtml(page, input);

      await expect.poll(async () => getSerializedHtml(page)).toBe(expected);
    });
  }

  test('clicking checkbox updates serialized html', async ({ page }) => {
    await setEditorHtml(
      page,
      '<html><ul data-type="checkbox"><li>one</li><li>two</li></ul></html>'
    );

    const editor = editorLocator(page);
    const checkbox = editor.locator('input[type="checkbox"]').first();
    await checkbox.click();

    await expect
      .poll(async () => getSerializedHtml(page))
      .toMatch(/<li checked[^>]*>one<\/li>/);

    const html = await getSerializedHtml(page);
    expect(html.match(/<li checked/g)?.length).toBe(1);
  });
});
