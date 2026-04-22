import { test, expect, type Page } from '@playwright/test';

import { toolbarButton } from '../helpers/toolbar';
import {
  editorLocator,
  gotoVisualRegression,
  setEditorHtml,
} from '../helpers/visual-regression';

async function selectParagraphTextInclusive(
  page: Page,
  fromIndex: number,
  toIndex: number
): Promise<void> {
  await page.evaluate(
    ({ from, to }) => {
      const root = document.querySelector('.eti-editor .ProseMirror');
      if (!root) throw new Error('ProseMirror root not found');

      const ps = root.querySelectorAll('p');
      const startP = ps.item(from);
      const endP = ps.item(to);
      if (!startP || !endP) {
        throw new Error(`paragraph index out of range (${from}..${to})`);
      }

      const range = document.createRange();
      range.setStart(startP, 0);
      range.setEnd(endP, endP.childNodes.length);

      const sel = window.getSelection();
      sel?.removeAllRanges();
      sel?.addRange(range);
    },
    { from: fromIndex, to: toIndex }
  );
}

const FIVE_PARAS_HTML = [
  '<html>',
  '<p>one</p>',
  '<p>two</p>',
  '<p>three</p>',
  '<p>four</p>',
  '<p>five</p>',
  '</html>',
].join('');

const ROUND_TRIP_SNAPSHOT = 'list-wrap-selection-round-trip.png';

const LIST_VARIANTS = [
  { label: 'bullet', toolbarTestId: 'unorderedList' as const },
  { label: 'ordered', toolbarTestId: 'orderedList' as const },
] as const;

for (const { label, toolbarTestId } of LIST_VARIANTS) {
  test.describe(`list wrap round-trip (${label})`, () => {
    test.beforeEach(async ({ page }) => {
      await gotoVisualRegression(page);
    });

    // Such a roundtrip ensures the selection isn't changed when toggling the list.
    test('toggle list on selection then off restores editor appearance', async ({
      page,
    }) => {
      await setEditorHtml(page, FIVE_PARAS_HTML);

      const editor = editorLocator(page);
      await editor.click();

      await expect(editor).toHaveScreenshot(ROUND_TRIP_SNAPSHOT);

      await selectParagraphTextInclusive(page, 1, 3);

      const listBtn = toolbarButton(page, toolbarTestId);
      await listBtn.click();
      await listBtn.click();

      await expect(editor).toHaveScreenshot(ROUND_TRIP_SNAPSHOT);
    });
  });
}
