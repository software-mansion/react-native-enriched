import { test, expect, type Page } from '@playwright/test';

const EDITOR_SELECTOR =
  '[data-testid="test-submit-root"] .eti-editor [contenteditable="true"]';
const SUBMIT_PAGE = '/test-submit-props';
const SUBMIT_LOG_SELECTOR = '[data-testid="submit-log"]';
const TYPE_DELAY_MS = 50;

interface SubmitLogSnapshot {
  submitCount: number;
  text: string;
}

async function readSubmitLog(page: Page): Promise<SubmitLogSnapshot> {
  const raw = await page.locator(SUBMIT_LOG_SELECTOR).innerText();
  return JSON.parse(raw.trim()) as SubmitLogSnapshot;
}

async function expectSubmitLog(
  page: Page,
  expected: SubmitLogSnapshot
): Promise<void> {
  await expect.poll(async () => readSubmitLog(page)).toStrictEqual(expected);
}

test.describe('submit and keyboard props', () => {
  test('newline mode inserts a paragraph break on Enter', async ({ page }) => {
    await page.goto(`${SUBMIT_PAGE}?mode=newline`);
    await page.waitForSelector(EDITOR_SELECTOR);

    const editor = page.locator(EDITOR_SELECTOR);
    await editor.click();
    await expect(editor).toBeFocused();

    await editor.pressSequentially(`Hello`, { delay: TYPE_DELAY_MS });
    await editor.press('Enter');
    await editor.pressSequentially(`World`, { delay: TYPE_DELAY_MS });

    await expect(page.locator('.eti-editor p')).toHaveCount(2);
    await expect(page.locator(SUBMIT_LOG_SELECTOR)).toContainText(
      '"submitCount":0'
    );
  });

  test('submit mode fires onSubmitEditing without adding a paragraph', async ({
    page,
  }) => {
    await page.goto(`${SUBMIT_PAGE}?mode=submit`);
    await page.waitForSelector(EDITOR_SELECTOR);

    const editor = page.locator(EDITOR_SELECTOR);
    await editor.click();
    await expect(editor).toBeFocused();

    await editor.pressSequentially(`Hi`, { delay: TYPE_DELAY_MS });
    await editor.press('Enter');

    await expectSubmitLog(page, {
      submitCount: 1,
      text: 'Hi',
    });

    await expect(page.locator('.eti-editor p')).toHaveCount(1);
  });

  test('blurAndSubmit fires onSubmitEditing without adding a paragraph then blurs', async ({
    page,
  }) => {
    await page.goto(`${SUBMIT_PAGE}?mode=blurAndSubmit`);
    await page.waitForSelector(EDITOR_SELECTOR);

    const editor = page.locator(EDITOR_SELECTOR);
    await editor.click();
    await expect(editor).toBeFocused();

    await editor.pressSequentially('x', { delay: TYPE_DELAY_MS });
    await editor.press('Enter');

    await expectSubmitLog(page, {
      submitCount: 1,
      text: 'x',
    });

    await expect(page.locator('.eti-editor p')).toHaveCount(1);
    await expect(editor).not.toBeFocused();
  });

  test('returnKeyType sets enterkeyhint on the editable root', async ({
    page,
  }) => {
    await page.goto(`${SUBMIT_PAGE}?enterKeyTest=1&returnKeyType=search`);
    await page.waitForSelector(EDITOR_SELECTOR);

    const editor = page.locator(EDITOR_SELECTOR);
    await expect(editor).toHaveAttribute('enterkeyhint', 'search');
  });
});
