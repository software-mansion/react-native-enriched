import { expect, type Locator, type Page } from '@playwright/test';

export const visualRegressionSelectors = {
  editor: '[data-testid="visual-regression-editor"]',
  editorInner: '[data-testid="visual-regression-editor"] .eti-editor',
  htmlInput: '[data-testid="visual-regression-html-input"]',
  setValueButton: '[data-testid="visual-regression-set-value-button"]',
  editorHtmlOutput: '[data-testid="visual-regression-editor-html-output"]',
  htmlStyleOverride: '[data-testid="visual-regression-html-style-override"]',
} as const;

export function editorLocator(page: Page): Locator {
  return page.locator(visualRegressionSelectors.editorInner);
}

export async function focusEnrichedEditable(page: Page): Promise<Locator> {
  const editor = editorLocator(page);
  await editor.click();
  await expect(
    editor.locator('[contenteditable="true"]').first()
  ).toBeFocused();
  return editor;
}

export async function gotoVisualRegression(page: Page): Promise<void> {
  await page.goto('/visual-regression');
  await page.waitForSelector(visualRegressionSelectors.editorInner);
}

export async function getSerializedHtml(page: Page): Promise<string> {
  return (
    (await page
      .locator(visualRegressionSelectors.editorHtmlOutput)
      .textContent()) ?? ''
  );
}

export async function setEditorHtml(page: Page, html: string): Promise<void> {
  await page.fill(visualRegressionSelectors.htmlInput, html);
  await page.click(visualRegressionSelectors.setValueButton);
  await expect
    .poll(async () => {
      const t = await getSerializedHtml(page);
      return t.startsWith('<html>');
    })
    .toBe(true);
}

export async function setHtmlStyleOverride(
  page: Page,
  json: string
): Promise<void> {
  await page.fill(visualRegressionSelectors.htmlStyleOverride, json);
}
