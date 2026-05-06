import { test, expect, type Page } from '@playwright/test';

import {
  editorLocator,
  getSerializedHtml,
  gotoVisualRegression,
  setEditorHtml,
} from '../helpers/visual-regression';
import { toolbarButton } from '../helpers/toolbar';

async function typeBoldText(page: Page, text: string): Promise<void> {
  const boldBtn = toolbarButton(page, 'bold');
  const editor = editorLocator(page);

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

  const editor = editorLocator(page);

  await editor.click();
  await expect(toolbarButton(page, 'bold')).not.toHaveClass(
    /toolbar-btn--active/
  );
  await editor.pressSequentially(plainText, { delay: 80 });
}

async function typeInlineCodeThenPlainText(
  page: Page,
  codeText: string,
  plainText: string
) {
  const inlineCodeBtn = toolbarButton(page, 'inlineCode');
  const editor = editorLocator(page);

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
    await gotoVisualRegression(page);
  });

  test('inline style deactivates after deleting inline-styled text char by char', async ({
    page,
  }) => {
    const editor = editorLocator(page);

    await typeBoldText(page, 'hello world');

    await editor.press('End');
    for (let i = 0; i < 'hello world'.length + 1; i++) {
      await editor.press('Backspace', { delay: 80 }); // slow + reliable
    }

    await expect(editor).toHaveText('');
    await expect(toolbarButton(page, 'bold')).not.toHaveClass(
      /toolbar-btn--active/
    );
  });

  test('inline style deactivates after cmd+a and delete', async ({ page }) => {
    const editor = editorLocator(page);

    await typeBoldText(page, 'hello world');

    await editor.press('Meta+A');
    await editor.press('Backspace');

    await expect(toolbarButton(page, 'bold')).not.toHaveClass(
      /toolbar-btn--active/
    );
  });

  test('inline style is inactive at document start and typed text is plain', async ({
    page,
  }) => {
    const editor = editorLocator(page);
    const boldBtn = toolbarButton(page, 'bold');

    await typeBoldText(page, 'hello');

    await editor.press('Home');
    await expect(boldBtn).not.toHaveClass(/toolbar-btn--active/);

    await editor.pressSequentially('X', { delay: 80 });
    await expect(boldBtn).not.toHaveClass(/toolbar-btn--active/);
  });

  test('pressing Enter after the last inline code character keeps code when the rest of the line is plain', async ({
    page,
  }) => {
    const editor = editorLocator(page);
    const inlineCodeBtn = toolbarButton(page, 'inlineCode');

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
    const editor = editorLocator(page);
    const boldBtn = toolbarButton(page, 'bold');

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
    const editor = editorLocator(page);
    const boldBtn = toolbarButton(page, 'bold');

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
    const editor = editorLocator(page);

    await typeBoldThenPlainText(page, 'hello', ' world');

    await editor.press('Home');

    for (let i = 0; i < 6; i++) {
      await editor.press('ArrowRight', { delay: 80 });
    }

    await editor.press('Backspace');

    await expect(toolbarButton(page, 'bold')).toHaveClass(
      /toolbar-btn--active/
    );
  });

  test('inline code stays active at boundary between code and plain text after deletion', async ({
    page,
  }) => {
    const editor = editorLocator(page);
    const inlineCodeBtn = toolbarButton(page, 'inlineCode');

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
    const editor = editorLocator(page);
    const boldBtn = toolbarButton(page, 'bold');

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
    const editor = editorLocator(page);
    const boldBtn = toolbarButton(page, 'bold');

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
    const editor = editorLocator(page);
    const boldBtn = toolbarButton(page, 'bold');

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
    const editor = editorLocator(page);
    const boldBtn = toolbarButton(page, 'bold');

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

  test('typing after the last linked character does not extend the link', async ({
    page,
  }) => {
    await setEditorHtml(
      page,
      '<html><p><a href="https://example.com">Hello</a></p></html>'
    );

    const editor = editorLocator(page);
    await editor.click();
    await editor.press('End');
    await editor.pressSequentially(' more', { delay: 80 });

    await expect
      .poll(async () => {
        const html = await getSerializedHtml(page);
        return (
          html.includes('<a href="https://example.com">Hello</a>') &&
          !html.includes('<a href="https://example.com">Hello more</a>')
        );
      })
      .toBe(true);
  });
});
