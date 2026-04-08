import { test, expect, type Page } from '@playwright/test';

const EDITOR_INNER = '[data-testid="visual-regression-editor"] .eti-editor';
const BOLD_TOOLBAR_BUTTON = '[data-testid="toolbar-button-bold"]';

async function typeBoldText(page: Page, text: string) {
  const boldBtn = page.locator(BOLD_TOOLBAR_BUTTON);
  const editor = page.locator(EDITOR_INNER);

  await editor.click();
  await boldBtn.click();
  await expect(boldBtn).toHaveClass(/toolbar-btn--active/);
  await editor.pressSequentially(text, { delay: 80 });
  await boldBtn.click();
  await expect(boldBtn).not.toHaveClass(/toolbar-btn--active/);
}

async function typeBoldThenPlainText(
  page: Page,
  boldText: string,
  plainText: string
) {
  await typeBoldText(page, boldText);

  const editor = page.locator(EDITOR_INNER);

  await editor.click();
  await expect(page.locator(BOLD_TOOLBAR_BUTTON)).not.toHaveClass(
    /toolbar-btn--active/
  );
  await editor.pressSequentially(plainText, { delay: 80 });
}

test.describe('strict marks', () => {
  test.beforeEach(async ({ page }) => {
    await page.goto('/visual-regression');
    await page.waitForSelector(EDITOR_INNER);
  });

  test('inline style deactivates after deleting inline-styled text char by char', async ({
    page,
  }) => {
    const editor = page.locator(EDITOR_INNER);

    await typeBoldText(page, 'hello world');
    await page.pause(); // keep for watching

    await editor.press('End');
    for (let i = 0; i < 'hello world'.length + 1; i++) {
      await editor.press('Backspace', { delay: 80 }); // slow + reliable
    }

    await expect(editor).toHaveText('');
    await page.pause();
    await expect(page.locator(BOLD_TOOLBAR_BUTTON)).not.toHaveClass(
      /toolbar-btn--active/
    );
  });

  test('inline style deactivates after cmd+a and delete', async ({ page }) => {
    const editor = page.locator(EDITOR_INNER);

    await typeBoldText(page, 'hello world');
    await page.pause();

    await editor.press('Meta+A');
    await editor.press('Backspace');

    await page.pause();
    await expect(page.locator(BOLD_TOOLBAR_BUTTON)).not.toHaveClass(
      /toolbar-btn--active/
    );
  });

  test('inline style is inactive at document start and typed text is plain', async ({
    page,
  }) => {
    const editor = page.locator(EDITOR_INNER);
    const boldBtn = page.locator(BOLD_TOOLBAR_BUTTON);

    await typeBoldText(page, 'hello');
    await page.pause();

    await editor.press('Home');
    await expect(boldBtn).not.toHaveClass(/toolbar-btn--active/);

    await editor.pressSequentially('X', { delay: 80 });
    await page.pause();
    await expect(boldBtn).not.toHaveClass(/toolbar-btn--active/);
  });

  test('inline style stays active at boundary between styled and plain text after deletion', async ({
    page,
  }) => {
    const editor = page.locator(EDITOR_INNER);

    await typeBoldThenPlainText(page, 'hello', ' world');
    await page.pause();

    await editor.press('Home');

    // move past "hello " (6 chars) to position cursor after the space
    for (let i = 0; i < 6; i++) {
      await editor.press('ArrowRight', { delay: 80 });
    }
    await page.pause();

    await editor.press('Backspace');
    await page.pause();

    await expect(page.locator(BOLD_TOOLBAR_BUTTON)).toHaveClass(
      /toolbar-btn--active/
    );
  });
});
