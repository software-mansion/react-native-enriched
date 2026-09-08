import { test, expect } from '@playwright/test';

const ROOT_SELECTOR = '[data-testid="test-render-cycle-root"]';
const EDITOR_SELECTOR = `${ROOT_SELECTOR} .eti-editor [contenteditable="true"]`;
const TOGGLE_BUTTON_SELECTOR = '[data-testid="toggle-variant-button"]';
const VARIANT_OUTPUT_SELECTOR = '[data-testid="variant-output"]';
const PAGE_PATH = '/test-render-cycle';

test.describe('EnrichedTextInput render cycle', () => {
  test('does not throw on simultaneous defaultValue and htmlStyle change', async ({
    page,
  }) => {
    const pageErrors: Error[] = [];
    const consoleErrors: string[] = [];

    page.on('pageerror', (error) => pageErrors.push(error));
    page.on('console', (message) => {
      if (message.type() === 'error') {
        consoleErrors.push(message.text());
      }
    });

    await page.goto(PAGE_PATH);
    await page.waitForSelector(EDITOR_SELECTOR);

    await expect(page.locator(EDITOR_SELECTOR)).toContainText('Variant A');

    await page.click(TOGGLE_BUTTON_SELECTOR);
    await expect(page.locator(VARIANT_OUTPUT_SELECTOR)).toHaveText('b');
    await expect(page.locator(EDITOR_SELECTOR)).toContainText('Variant B');

    await page.click(TOGGLE_BUTTON_SELECTOR);
    await expect(page.locator(VARIANT_OUTPUT_SELECTOR)).toHaveText('a');
    await expect(page.locator(EDITOR_SELECTOR)).toContainText('Variant A');

    const editor = page.locator(EDITOR_SELECTOR);
    await editor.click();
    await expect(editor).toBeFocused();
    await editor.pressSequentially(' more text');
    await expect(editor).toContainText('Variant A more text');

    expect(pageErrors).toEqual([]);
    expect(consoleErrors).toEqual([]);
  });
});
