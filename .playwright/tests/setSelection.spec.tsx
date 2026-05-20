import { test, expect } from '@playwright/test';

const SAMPLE_TEXT = 'AAAA\n\n\nBBBB\nCCCC';

function clampSelection(start: number, end: number, len: number) {
  const clampedStart = Math.max(0, Math.min(start, len));
  const clampedEnd = Math.max(clampedStart, Math.min(end, len));
  return { start: clampedStart, end: clampedEnd };
}

function getExpectedSelectedText(start: number, end: number): string {
  const { start: clampedStart, end: clampedEnd } = clampSelection(
    start,
    end,
    SAMPLE_TEXT.length
  );
  return SAMPLE_TEXT.slice(clampedStart, clampedEnd);
}

const cases: { start: number; end: number }[] = [
  { start: 0, end: 0 },
  { start: 1, end: 1 },
  { start: 4, end: 4 },
  { start: 5, end: 5 },
  { start: 6, end: 6 },
  { start: 7, end: 7 },
  { start: 8, end: 8 },
  { start: 11, end: 11 },
  { start: 12, end: 12 },
  { start: 16, end: 16 },
  { start: 0, end: 1 },
  { start: 0, end: 4 },
  { start: 0, end: 5 },
  { start: 0, end: 7 },
  { start: 4, end: 7 },
  { start: 4, end: 8 },
  { start: 5, end: 8 },
  { start: 6, end: 8 },
  { start: 7, end: 12 },
  { start: 8, end: 12 },
  { start: 11, end: 16 },
  { start: 12, end: 16 },
  { start: 0, end: 16 },
  { start: 16, end: 100 },
  { start: 100, end: 100 },
];

test.describe('setSelection component tests', () => {
  for (const { start, end } of cases) {
    test(`setSelection(${String(start)}, ${String(end)})`, async ({ page }) => {
      await page.goto('/test-set-selection');
      await page.waitForSelector('[data-testid="editor-container"]');

      const expectedText = getExpectedSelectedText(start, end);
      const expectedJson = JSON.stringify(expectedText);

      await page.getByTestId('selection-start-input').fill(String(start));
      await page.getByTestId('selection-end-input').fill(String(end));
      await page.getByTestId('apply-selection-button').click();

      await expect(page.getByTestId('selected-text-json')).toHaveValue(
        expectedJson
      );
    });
  }
});
