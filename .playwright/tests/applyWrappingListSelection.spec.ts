import { test, expect } from '@playwright/test';

import { selectParagraphTextInclusive } from '../helpers/selection';
import { toolbarButton } from '../helpers/toolbar';
import {
  editorLocator,
  gotoVisualRegression,
  setEditorHtml,
} from '../helpers/visual-regression';

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
  { label: 'bullet', toolbarTestId: 'unorderedList' },
  { label: 'ordered', toolbarTestId: 'orderedList' },
  { label: 'checkbox', toolbarTestId: 'checkboxList' },
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
