import { test, expect } from '@playwright/test';

import { selectParagraphTextInclusive } from '../helpers/selection';
import { toolbarButton } from '../helpers/toolbar';
import {
  editorLocator,
  getSerializedHtml,
  gotoVisualRegression,
  setEditorHtml,
} from '../helpers/visual-regression';

const TOOLBAR_CHECKBOX_HTML = [
  '<html>',
  '<p>pad</p>',
  '<p>one</p>',
  '<p>two</p>',
  '<p>pad</p>',
  '</html>',
].join('');

test.describe('checkbox list (web)', () => {
  test.beforeEach(async ({ page }) => {
    await gotoVisualRegression(page);
  });

  test('toolbar applies checkbox list with checked items (serialized html)', async ({
    page,
  }) => {
    await setEditorHtml(page, TOOLBAR_CHECKBOX_HTML);

    const editor = editorLocator(page);
    await editor.click();
    await selectParagraphTextInclusive(page, 1, 2);
    await toolbarButton(page, 'checkboxList').click();

    await expect
      .poll(async () => getSerializedHtml(page))
      .toMatch(/<ul data-type="checkbox">/);
    await expect
      .poll(async () => getSerializedHtml(page))
      .toMatch(/<li checked[^>]*>one<\/li>/);
    await expect
      .poll(async () => getSerializedHtml(page))
      .toMatch(/<li checked[^>]*>two<\/li>/);
  });

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
