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
    await expect(editor.locator('strong, b')).toHaveText('Hello World');

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
});
