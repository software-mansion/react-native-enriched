import { test, expect, type Page } from '@playwright/test';

import {
  focusEnrichedEditable,
  getSerializedHtml,
  gotoVisualRegression,
} from '../helpers/visual-regression';
import { toolbarButton } from '../helpers/toolbar';
import { selectRange } from '../helpers/selection';

// Tiptap History debounces consecutive typing into a single
// undo entry for ~500ms. Waiting past that creates separate
// entries that can be undone independently.
const HISTORY_GROUP_DELAY = 600;

const MOD = process.platform === 'darwin' ? 'Meta' : 'Control';

async function pressUndo(page: Page) {
  await page.keyboard.press(`${MOD}+z`);
}

async function pressRedo(page: Page) {
  await page.keyboard.press(`${MOD}+Shift+z`);
}

test.describe('undo / redo', () => {
  test.beforeEach(async ({ page }) => {
    await gotoVisualRegression(page);
    await focusEnrichedEditable(page);
  });

  test('undoes plain typed text', async ({ page }) => {
    await page.keyboard.type('Hello');
    await page.waitForTimeout(HISTORY_GROUP_DELAY);
    await page.keyboard.type(' World');

    expect(await getSerializedHtml(page)).toEqual(
      '<html><p>Hello World</p></html>'
    );

    await pressUndo(page);

    const after = await getSerializedHtml(page);
    expect(after).toEqual('<html><p>Hello</p></html>');
  });

  test('undoes and redoes plain typed text', async ({ page }) => {
    await page.keyboard.type('Hello');
    await page.waitForTimeout(HISTORY_GROUP_DELAY);
    await page.keyboard.type(' World');
    await page.waitForTimeout(HISTORY_GROUP_DELAY);
    await page.keyboard.type('!');

    await pressUndo(page);
    expect(await getSerializedHtml(page)).toEqual(
      '<html><p>Hello World</p></html>'
    );

    await pressUndo(page);
    expect(await getSerializedHtml(page)).toEqual('<html><p>Hello</p></html>');

    await pressRedo(page);
    expect(await getSerializedHtml(page)).toEqual(
      '<html><p>Hello World</p></html>'
    );

    await pressRedo(page);
    expect(await getSerializedHtml(page)).toEqual(
      '<html><p>Hello World!</p></html>'
    );
  });

  test('undoes a bold style applied to a selection', async ({ page }) => {
    await page.keyboard.type('Hello World');
    await page.waitForTimeout(HISTORY_GROUP_DELAY);

    await page.keyboard.press(`${MOD}+a`);
    await toolbarButton(page, 'bold').click();

    expect(await getSerializedHtml(page)).toEqual(
      '<html><p><b>Hello World</b></p></html>'
    );

    await pressUndo(page);

    const after = await getSerializedHtml(page);
    expect(after).toEqual('<html><p>Hello World</p></html>');
  });

  test('undoes and redoes a bold style applied to a selection', async ({
    page,
  }) => {
    await page.keyboard.type('Hello World!');
    await page.waitForTimeout(HISTORY_GROUP_DELAY);

    await page.keyboard.press(`${MOD}+a`);
    await toolbarButton(page, 'bold').click();
    await page.waitForTimeout(HISTORY_GROUP_DELAY);
    await selectRange(page, 6, 11);
    await toolbarButton(page, 'italic').click();
    expect(await getSerializedHtml(page)).toEqual(
      '<html><p><b>Hello <i>World</i>!</b></p></html>'
    );

    await pressUndo(page);
    expect(await getSerializedHtml(page)).toEqual(
      '<html><p><b>Hello World!</b></p></html>'
    );

    await pressRedo(page);
    expect(await getSerializedHtml(page)).toEqual(
      '<html><p><b>Hello <i>World</i>!</b></p></html>'
    );
  });

  test('undoes a heading paragraph style', async ({ page }) => {
    await page.keyboard.type('Hello');
    await page.waitForTimeout(HISTORY_GROUP_DELAY);

    await toolbarButton(page, 'h1').click();
    expect(await getSerializedHtml(page)).toEqual(
      '<html><h1>Hello</h1></html>'
    );

    await pressUndo(page);

    const after = await getSerializedHtml(page);
    expect(after).toEqual('<html><p>Hello</p></html>');
  });

  test('undoes and redoes a heading paragraph style', async ({ page }) => {
    await page.keyboard.type('Hello World!');
    await page.waitForTimeout(HISTORY_GROUP_DELAY);

    await selectRange(page, 6, 11);
    await toolbarButton(page, 'bold').click();
    await page.waitForTimeout(HISTORY_GROUP_DELAY);

    await toolbarButton(page, 'h1').click();
    await pressUndo(page);

    expect(await getSerializedHtml(page)).toEqual(
      '<html><p>Hello <b>World</b>!</p></html>'
    );

    await pressRedo(page);
    expect(await getSerializedHtml(page)).toEqual(
      '<html><h1>Hello World!</h1></html>'
    );
  });
});
