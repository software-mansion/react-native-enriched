import { test, expect, type Page } from '@playwright/test';

const EDITOR_INNER = '[data-testid="visual-regression-editor"] .eti-editor';
const BOLD_TOOLBAR_BUTTON = '[data-testid="toolbar-button-bold"]';
const INLINE_CODE_TOOLBAR_BUTTON = '[data-testid="toolbar-button-inlineCode"]';

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

async function typeInlineCodeThenPlainText(
  page: Page,
  codeText: string,
  plainText: string
) {
  const inlineCodeBtn = page.locator(INLINE_CODE_TOOLBAR_BUTTON);
  const editor = page.locator(EDITOR_INNER);

  await editor.click();
  await inlineCodeBtn.click();
  await expect(inlineCodeBtn).toHaveClass(/toolbar-btn--active/);
  await editor.pressSequentially(codeText, { delay: 80 });
  await inlineCodeBtn.click();
  await expect(inlineCodeBtn).not.toHaveClass(/toolbar-btn--active/);
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

    await editor.press('End');
    for (let i = 0; i < 'hello world'.length + 1; i++) {
      await editor.press('Backspace', { delay: 80 }); // slow + reliable
    }

    await expect(editor).toHaveText('');
    await expect(page.locator(BOLD_TOOLBAR_BUTTON)).not.toHaveClass(
      /toolbar-btn--active/
    );
  });

  test('inline style deactivates after cmd+a and delete', async ({ page }) => {
    const editor = page.locator(EDITOR_INNER);

    await typeBoldText(page, 'hello world');

    await editor.press('Meta+A');
    await editor.press('Backspace');

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

    await editor.press('Home');
    await expect(boldBtn).not.toHaveClass(/toolbar-btn--active/);

    await editor.pressSequentially('X', { delay: 80 });
    await expect(boldBtn).not.toHaveClass(/toolbar-btn--active/);
  });

  test('pressing Enter after the last inline code character keeps code when the rest of the line is plain', async ({
    page,
  }) => {
    const editor = page.locator(EDITOR_INNER);
    const inlineCodeBtn = page.locator(INLINE_CODE_TOOLBAR_BUTTON);

    await typeInlineCodeThenPlainText(page, 'code', ' plain');

    await editor.press('Home');
    for (let i = 0; i < 'code'.length; i++) {
      await editor.press('ArrowRight', { delay: 80 });
    }
    await expect(inlineCodeBtn).toHaveClass(/toolbar-btn--active/);

    await editor.press('Enter');
    await expect(inlineCodeBtn).toHaveClass(/toolbar-btn--active/);
  });

  test('pressing Enter in the middle of a styled segment carries style to the new line', async ({
    page,
  }) => {
    const editor = page.locator(EDITOR_INNER);
    const boldBtn = page.locator(BOLD_TOOLBAR_BUTTON);

    await editor.click();
    await boldBtn.click();
    await expect(boldBtn).toHaveClass(/toolbar-btn--active/);
    await editor.pressSequentially('hello world', { delay: 80 });

    await editor.press('Home');
    for (let i = 0; i < 'hello'.length; i++) {
      await editor.press('ArrowRight', { delay: 80 });
    }

    await editor.press('Enter');

    await expect(boldBtn).toHaveClass(/toolbar-btn--active/);
  });

  test('pressing Enter after the last bold character keeps bold when the rest of the line is plain', async ({
    page,
  }) => {
    const editor = page.locator(EDITOR_INNER);
    const boldBtn = page.locator(BOLD_TOOLBAR_BUTTON);

    await typeBoldThenPlainText(page, 'hello', ' something');

    await editor.press('Home');
    for (let i = 0; i < 'hello'.length; i++) {
      await editor.press('ArrowRight', { delay: 80 });
    }

    await expect(boldBtn).toHaveClass(/toolbar-btn--active/);

    await editor.press('Enter');

    await expect(boldBtn).toHaveClass(/toolbar-btn--active/);
  });

  test('inline style stays active at boundary between styled and plain text after deletion', async ({
    page,
  }) => {
    const editor = page.locator(EDITOR_INNER);

    await typeBoldThenPlainText(page, 'hello', ' world');

    await editor.press('Home');

    for (let i = 0; i < 6; i++) {
      await editor.press('ArrowRight', { delay: 80 });
    }

    await editor.press('Backspace');

    await expect(page.locator(BOLD_TOOLBAR_BUTTON)).toHaveClass(
      /toolbar-btn--active/
    );
  });

  test('inline code stays active at boundary between code and plain text after deletion', async ({
    page,
  }) => {
    const editor = page.locator(EDITOR_INNER);
    const inlineCodeBtn = page.locator(INLINE_CODE_TOOLBAR_BUTTON);

    await typeInlineCodeThenPlainText(page, 'hello', ' world');

    await editor.press('Home');

    for (let i = 0; i < 6; i++) {
      await editor.press('ArrowRight', { delay: 80 });
    }

    await editor.press('Backspace');

    await expect(inlineCodeBtn).toHaveClass(/toolbar-btn--active/);
  });

  test('explicit style survives multiple Enter and Backspace keystrokes on empty lines', async ({
    page,
  }) => {
    const editor = page.locator(EDITOR_INNER);
    const boldBtn = page.locator(BOLD_TOOLBAR_BUTTON);

    await editor.click();
    await boldBtn.click();
    await expect(boldBtn).toHaveClass(/toolbar-btn--active/);

    await editor.press('Enter', { delay: 50 });
    await editor.press('Enter', { delay: 50 });
    await editor.press('Enter', { delay: 50 });

    await expect(boldBtn).toHaveClass(/toolbar-btn--active/);

    await editor.press('Backspace', { delay: 50 });
    await editor.press('Backspace', { delay: 50 });

    await expect(boldBtn).toHaveClass(/toolbar-btn--active/);
  });

  test('style clears when deleting the last character of a specific line', async ({
    page,
  }) => {
    const editor = page.locator(EDITOR_INNER);
    const boldBtn = page.locator(BOLD_TOOLBAR_BUTTON);

    await editor.click();
    await editor.pressSequentially('Line 1');
    await editor.press('Enter');

    await boldBtn.click();
    await expect(boldBtn).toHaveClass(/toolbar-btn--active/);
    await editor.pressSequentially('Bold', { delay: 50 });

    await expect(boldBtn).toHaveClass(/toolbar-btn--active/);

    for (let i = 0; i < 4; i++) {
      await editor.press('Backspace', { delay: 50 });
    }

    await expect(boldBtn).not.toHaveClass(/toolbar-btn--active/);
  });

  test('can toggle inline style off when cursor is inside styled text', async ({
    page,
  }) => {
    const editor = page.locator(EDITOR_INNER);
    const boldBtn = page.locator(BOLD_TOOLBAR_BUTTON);

    await typeBoldText(page, 'hello');

    await editor.press('ArrowLeft', { delay: 80 });
    await editor.press('ArrowLeft', { delay: 80 });

    await expect(boldBtn).toHaveClass(/toolbar-btn--active/);

    await boldBtn.click();

    await expect(boldBtn).not.toHaveClass(/toolbar-btn--active/);
    await editor.pressSequentially('X', { delay: 80 });
    await expect(boldBtn).not.toHaveClass(/toolbar-btn--active/);
  });

  test('style inherits from previous block when clearing a newly created line', async ({
    page,
  }) => {
    const editor = page.locator(EDITOR_INNER);
    const boldBtn = page.locator(BOLD_TOOLBAR_BUTTON);

    await editor.click();
    await boldBtn.click();
    await expect(boldBtn).toHaveClass(/toolbar-btn--active/);
    await editor.pressSequentially('Bold Line', { delay: 80 });

    await editor.press('Enter');
    await expect(boldBtn).toHaveClass(/toolbar-btn--active/);

    await editor.pressSequentially('Temp', { delay: 80 });

    for (let i = 0; i < 'Temp'.length; i++) {
      await editor.press('Backspace', { delay: 80 });
    }

    await expect(boldBtn).toHaveClass(/toolbar-btn--active/);
  });
});
