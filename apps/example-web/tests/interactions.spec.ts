import { test, expect } from '@playwright/test';

test.describe('EnrichedTextInput Interactions', () => {
  test.beforeEach(async ({ page }) => {
    await page.goto('/');
    // Clear default content if necessary.
    // Based on App.tsx, there is default value.
    // We can select all and delete to start fresh.
    const editor = page.locator('.ProseMirror');
    await editor.click();
    await editor.press('Meta+A');
    await editor.press('Backspace');
  });

  test('toggling bold then header results in header applied and bold removed', async ({
    page,
  }) => {
    const editor = page.locator('.ProseMirror');

    // 1. Type text
    await editor.pressSequentially('Hello World');

    // 2. Select text
    await editor.press('Meta+A');

    // 3. Toggle Bold
    const boldBtn = page.getByRole('button', { name: 'B', exact: true });
    await boldBtn.click();

    // Verification 1: Bold is active
    await expect(boldBtn).toHaveClass(/active/);
    await expect(editor.locator('b')).toHaveText('Hello World');

    // 4. Toggle Header 1
    const h1Btn = page.getByRole('button', { name: 'H1', exact: true });
    await h1Btn.click();

    // Verification 2: Header 1 is active
    await expect(h1Btn).toHaveClass(/active/);
    await expect(editor.locator('h1')).toHaveText('Hello World');

    // Verification 3: Bold is NOT active (based on schema configuration in EnrichedTextInput.tsx)
    // The Heading extension was configured with marks: 'italic underline strike code', but NOT bold.
    await expect(boldBtn).not.toHaveClass(/active/);
    // Ensure no bold tag exists inside the h1 or around it for this text
    await expect(editor.locator('b')).toBeHidden();
  });

  test('applying bold then inline code results in both applied', async ({
    page,
  }) => {
    const editor = page.locator('.ProseMirror');

    // 1. Type text
    await editor.pressSequentially('Mixed Styles');

    // 2. Select text
    await editor.press('Meta+A');

    // 3. Toggle Bold
    const boldBtn = page.getByRole('button', { name: 'B', exact: true });
    await boldBtn.click();

    // Verification 1: Bold is active
    await expect(boldBtn).toHaveClass(/active/);

    // 4. Toggle Inline Code
    const codeBtn = page.getByRole('button', { name: 'IC', exact: true }); // Label from Toolbar.tsx
    await codeBtn.click();

    // Verification 2: Both Bold and Code buttons are active
    await expect(boldBtn).toHaveClass(/active/);
    await expect(codeBtn).toHaveClass(/active/);

    // Verification 3: DOM check - should have code inside bold or vice versa
    // Example: <b><code>Mixed Styles</code></b>
    await expect(editor.locator('code')).toHaveText('Mixed Styles');
    await expect(editor.locator('b')).toHaveText('Mixed Styles');
  });

  test('headings and blockquote show conflicting state when H1 is active', async ({
    page,
  }) => {
    const editor = page.locator('.ProseMirror');

    // 1. Type text
    await editor.pressSequentially('Heading Text');

    // 2. Click H1
    const h1Btn = page.getByRole('button', { name: 'H1', exact: true });
    await h1Btn.click();

    // Verify H1 is active
    await expect(h1Btn).toHaveClass(/active/);

    // Verify other Headings and Blockquote are conflicting
    const conflictButtonsIds = ['H2', 'H3', 'H4', 'H5', 'H6', 'Quote'];
    for (const name of conflictButtonsIds) {
      const btn = page.getByRole('button', { name, exact: true });
      await expect(btn).toHaveClass(/conflicting/);
    }

    // 3. Toggle off H1
    await h1Btn.click();

    // Verify H1 is not active
    await expect(h1Btn).not.toHaveClass(/active/);

    // Verify others are not conflicting
    for (const name of conflictButtonsIds) {
      const btn = page.getByRole('button', { name, exact: true });
      await expect(btn).not.toHaveClass(/conflicting/);
    }
  });

  test('headings show conflicting state when Blockquote is active', async ({
    page,
  }) => {
    const editor = page.locator('.ProseMirror');

    // 1. Type text
    await editor.pressSequentially('Quote Text');

    // 2. Click Blockquote
    const quoteBtn = page.getByRole('button', { name: 'Quote', exact: true });
    await quoteBtn.click();

    // Verify Quote is active
    await expect(quoteBtn).toHaveClass(/active/);

    // Verify H1-H6 are conflicting
    const conflictButtonsIds = ['H1', 'H2', 'H3', 'H4', 'H5', 'H6'];
    for (const name of conflictButtonsIds) {
      const btn = page.getByRole('button', { name, exact: true });
      await expect(btn).toHaveClass(/conflicting/);
    }

    // 3. Toggle off Blockquote
    await quoteBtn.click();

    // Verify Quote is not active
    await expect(quoteBtn).not.toHaveClass(/active/);

    // Verify others are not conflicting
    for (const name of conflictButtonsIds) {
      const btn = page.getByRole('button', { name, exact: true });
      await expect(btn).not.toHaveClass(/conflicting/);
    }
  });

  test('selecting multiple lines with different styles and applying Header results in conflicting styles removed', async ({
    page,
  }) => {
    const editor = page.locator('.ProseMirror');

    // 1. Line 1: Bold Text
    // Use toggle-type-toggle pattern to avoid selection issues
    await page.getByRole('button', { name: 'B', exact: true }).click();
    await editor.pressSequentially('Bold Text');
    // Toggle off bold so next lines aren't bold by default (though we clear styles with H1 later)
    await page.getByRole('button', { name: 'B', exact: true }).click();
    await editor.press('Enter');

    // 2. Line 2: Inline Code Text
    await page.getByRole('button', { name: 'IC', exact: true }).click();
    await editor.pressSequentially('Code Text');
    await page.getByRole('button', { name: 'IC', exact: true }).click();
    await editor.press('Enter');

    // 3. Line 3: Heading 3 Text
    await editor.pressSequentially('Heading Text');
    await page.getByRole('button', { name: 'H3', exact: true }).click();
    await editor.press('Enter');

    // 4. Line 4: Quote Text
    await editor.pressSequentially('Quote Text');
    await page.getByRole('button', { name: 'Quote', exact: true }).click();

    // 5. Select All
    await editor.press('Meta+A');

    // 6. Apply Header 1 (which conflicts with Bold and Quote but supports Code)
    const h1Btn = page.getByRole('button', { name: 'H1', exact: true });
    await h1Btn.click();

    // Verification
    // All 4 lines should now be H1
    await expect(editor.locator('h1')).toHaveCount(4);

    // Line 1: Bold should be removed
    const boldLine = editor.locator('h1').filter({ hasText: 'Bold Text' });
    await expect(boldLine.locator('b')).toBeHidden();

    // Line 2: Code should be preserved
    const codeLine = editor.locator('h1').filter({ hasText: 'Code Text' });
    await expect(codeLine.locator('code')).toBeVisible();

    // Line 3: Should be H1 (verified by count and filter)
    const headingLine = editor
      .locator('h1')
      .filter({ hasText: 'Heading Text' });
    await expect(headingLine).toBeVisible();

    // Line 4: Quote should be converted to H1 (no blockquote)
    const quoteLine = editor.locator('h1').filter({ hasText: 'Quote Text' });
    await expect(quoteLine).toBeVisible();
    await expect(editor.locator('blockquote')).toBeHidden();
  });
});
