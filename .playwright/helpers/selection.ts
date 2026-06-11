import type { Page } from '@playwright/test';

export async function selectParagraphTextInclusive(
  page: Page,
  fromIndex: number,
  toIndex: number
): Promise<void> {
  await page.evaluate(
    ({ from, to }) => {
      const root = document.querySelector('.eti-editor .ProseMirror');
      if (!root) throw new Error('ProseMirror root not found');

      const ps = root.querySelectorAll('p');
      const startP = ps.item(from);
      const endP = ps.item(to);
      if (!startP || !endP) {
        throw new Error(`paragraph index out of range (${from}..${to})`);
      }

      const range = document.createRange();
      range.setStart(startP, 0);
      range.setEnd(endP, endP.childNodes.length);

      const sel = window.getSelection();
      sel?.removeAllRanges();
      sel?.addRange(range);
    },
    { from: fromIndex, to: toIndex }
  );
}

export async function selectRange(page: Page, start: number, end: number) {
  await page.keyboard.press('Home');

  for (let i = 0; i < start; i++) {
    await page.keyboard.press('ArrowRight');
  }

  await page.keyboard.down('Shift');
  for (let i = 0; i < end - start; i++) {
    await page.keyboard.press('ArrowRight');
  }
  await page.keyboard.up('Shift');
}
