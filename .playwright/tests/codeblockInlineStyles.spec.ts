import { test, expect } from '@playwright/test';

import { copyAndPasteBetween } from '../helpers/clipboard';
import {
  editorLocator,
  getSerializedHtml,
  gotoVisualRegression,
  setEditorHtml,
} from '../helpers/visual-regression';
import { toolbarButton } from '../helpers/toolbar';

const INLINE_MARK_TAG = /<\s*(b|i|u|s|code)\b/i;

function htmlInsideCodeblock(serialized: string): string {
  const m = serialized.match(/<codeblock[^>]*>([\s\S]*?)<\/codeblock>/i);
  return m ? m[1] : '';
}

test.describe('codeblock inline styles', () => {
  test.beforeEach(async ({ page }) => {
    await gotoVisualRegression(page);
  });

  test('inline toolbar controls are disabled inside code block', async ({
    page,
  }) => {
    await setEditorHtml(
      page,
      '<html><codeblock><p>Inside code</p></codeblock></html>'
    );

    await page.locator('.eti-editor codeblock p').click();

    for (const key of [
      'bold',
      'italic',
      'underline',
      'strikeThrough',
      'inlineCode',
      'link',
    ] as const) {
      await expect(toolbarButton(page, key)).toBeDisabled();
    }
  });

  test('setValue strips inline styles inside code block', async ({ page }) => {
    await setEditorHtml(
      page,
      '<html><codeblock><p><b>bold</b> <i>italic</i> <u>underline</u> <s>strike</s> <code>inline</code></p></codeblock></html>'
    );

    const html = await getSerializedHtml(page);
    expect(htmlInsideCodeblock(html)).not.toMatch(INLINE_MARK_TAG);

    await expect(editorLocator(page)).toHaveScreenshot(
      'codeblock-inline-styles-setvalue-stripped.png'
    );
  });

  test('paste into code block strips copied inline styles', async ({
    page,
  }) => {
    await setEditorHtml(
      page,
      '<html><p><b>pasteMe</b></p><codeblock><p>placeholder</p></codeblock></html>'
    );

    await copyAndPasteBetween(
      page.locator('.eti-editor p').first(),
      page.locator('.eti-editor codeblock p')
    );

    const htmlAfterPaste = await getSerializedHtml(page);
    expect(htmlInsideCodeblock(htmlAfterPaste)).not.toMatch(INLINE_MARK_TAG);

    await expect(editorLocator(page)).toHaveScreenshot(
      'codeblock-inline-styles-paste-stripped.png'
    );
  });
});
