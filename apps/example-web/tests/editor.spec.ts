import { test, expect } from '@playwright/test';

test.describe('example-web editor', () => {
  test('renders editor with placeholder and toggles HTML output', async ({
    page,
  }) => {
    await page.goto('/');

    await expect(
      page.getByRole('heading', { name: 'Enriched Text Input' })
    ).toBeVisible();

    const editor = page.getByTestId('editor-wrapper').locator('.eti-editor');
    await expect(editor).toBeVisible();
    await expect(editor).toHaveAttribute('data-placeholder', 'Type something');

    // HTML output is hidden until user clicks "Show HTML"
    await expect(page.getByTestId('html-output-pre')).toHaveCount(0);

    await page.getByTestId('toggle-html-button').click();
    const htmlPre = page.getByTestId('html-output-pre');
    await expect(htmlPre).toBeVisible();
    await expect(htmlPre).not.toBeEmpty();

    await editor.click();
    await page.keyboard.type('Hello from Playwright');

    await expect(htmlPre).toContainText('Hello from Playwright');

    // Toggle back
    await page.getByTestId('toggle-html-button').click();
    await expect(page.getByTestId('html-output-pre')).toHaveCount(0);
  });

  test('can set editor value via modal', async ({ page }) => {
    await page.goto('/');

    // Show HTML output so we can assert the editor content after the modal sets it.
    await page.getByTestId('toggle-html-button').click();
    const htmlPre = page.getByTestId('html-output-pre');
    await expect(htmlPre).toBeVisible();

    await page.getByTestId('open-set-value-modal-button').click();

    const modalTextarea = page.getByTestId('set-value-modal-input');
    await expect(modalTextarea).toBeVisible();

    await modalTextarea.fill('<p>Modal value</p>');
    await page.getByTestId('set-value-modal-submit').click();

    await expect(modalTextarea).not.toBeVisible();
    await expect(htmlPre).toContainText('Modal value');
  });

  test('can set selection via modal and replace selected text', async ({
    page,
  }) => {
    await page.goto('/');

    await page.getByTestId('toggle-html-button').click();
    const htmlPre = page.getByTestId('html-output-pre');
    await expect(htmlPre).toBeVisible();

    await page.getByTestId('open-set-value-modal-button').click();
    const valueModalTextarea = page.getByTestId('set-value-modal-input');
    await expect(valueModalTextarea).toBeVisible();
    await valueModalTextarea.fill('<p>Hello world</p>');
    await page.getByTestId('set-value-modal-submit').click();
    await expect(htmlPre).toContainText('Hello world');

    await page.getByTestId('open-set-selection-modal-button').click();
    const startInput = page.getByTestId('set-selection-modal-start-input');
    const endInput = page.getByTestId('set-selection-modal-end-input');

    await expect(startInput).toBeVisible();
    await startInput.fill('6');
    await endInput.fill('11');
    await page.getByTestId('set-selection-modal-submit').click();

    await page.keyboard.type('RN');

    await expect(htmlPre).toContainText('Hello RN');
    await expect(htmlPre).not.toContainText('world');
  });
});
