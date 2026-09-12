import { test, expect, type Page } from '@playwright/test';

import { copySelectionFrom } from '../helpers/clipboard';

async function pasteAtCurrentSelection(page: Page): Promise<void> {
  await page.keyboard.press('ControlOrMeta+V');
}

test.setTimeout(90_000);

const sel = {
  editorInner: '[data-testid="test-max-length-editor"] .eti-editor',
  maxLengthInput: '[data-testid="test-max-length-maxlength-input"]',
  htmlInput: '[data-testid="test-max-length-html-input"]',
  setValueButton: '[data-testid="test-max-length-set-value-button"]',
  htmlOutput: '[data-testid="test-max-length-html-output"]',
  selectionStart: '[data-testid="test-max-length-selection-start"]',
  selectionEnd: '[data-testid="test-max-length-selection-end"]',
  applySelection: '[data-testid="test-max-length-apply-selection-button"]',
  setLinkStart: '[data-testid="test-max-length-setlink-start"]',
  setLinkEnd: '[data-testid="test-max-length-setlink-end"]',
  setLinkText: '[data-testid="test-max-length-setlink-text"]',
  setLinkUrl: '[data-testid="test-max-length-setlink-url"]',
  applySetLink: '[data-testid="test-max-length-apply-setlink-button"]',
  mentionIndicator: '[data-testid="test-max-length-mention-indicator"]',
  mentionText: '[data-testid="test-max-length-mention-text"]',
  setMentionButton: '[data-testid="test-max-length-set-mention-button"]',
  startMentionButton: '[data-testid="test-max-length-start-mention-button"]',
  imageSrc: '[data-testid="test-max-length-image-src"]',
  imageWidth: '[data-testid="test-max-length-image-width"]',
  imageHeight: '[data-testid="test-max-length-image-height"]',
  setImageButton: '[data-testid="test-max-length-set-image-button"]',
} as const;

async function gotoTestMaxLength(page: Page): Promise<void> {
  await page.goto('/test-max-length');
  await page.waitForSelector(sel.editorInner);

  const routePattern = '**/pw-e2e-ok.png';
  const pngBody = Buffer.from(
    'iVBORw0KGgoAAAANSUhEUgAAAAEAAAABCAYAAAAfFcSJAAAADUlEQVR42mP8z8BQDwAEhQGAhKmMIQAAAABJRU5ErkJggg==',
    'base64'
  );
  await page.route(routePattern, async (route) => {
    await route.fulfill({
      status: 200,
      contentType: 'image/png',
      body: pngBody,
    });
  });
}

async function getHtmlOutput(page: Page): Promise<string> {
  return (await page.locator(sel.htmlOutput).textContent()) ?? '';
}

async function setValue(page: Page, html: string): Promise<void> {
  await page.fill(sel.htmlInput, html);
  await page.click(sel.setValueButton);
  await expect
    .poll(async () => {
      const t = await getHtmlOutput(page);
      return t.startsWith('<html>');
    })
    .toBe(true);
}

async function setSelection(
  page: Page,
  start: number,
  end: number
): Promise<void> {
  await page.fill(sel.selectionStart, String(start));
  await page.fill(sel.selectionEnd, String(end));
  await page.click(sel.applySelection);
  // Clicking the button moves DOM focus away from the editor even though the
  // ProseMirror selection itself is preserved; refocus so keyboard input lands.
  await page.locator(`${sel.editorInner} .ProseMirror`).focus();
}

function firstParagraph(page: Page) {
  return page.locator(sel.editorInner).locator('p').first();
}

async function focusEditor(page: Page) {
  const editor = page.locator(sel.editorInner);
  await firstParagraph(page).click();
  await expect(editor.locator('.ProseMirror')).toBeFocused();
  return editor;
}

test.describe('test-max-length typing', () => {
  test('typing stops accepting characters once maxLength is reached', async ({
    page,
  }) => {
    await gotoTestMaxLength(page);
    await setValue(page, '<html><p></p></html>');

    await focusEditor(page);
    await page.keyboard.type('12345678901234', { delay: 20 });

    await expect
      .poll(async () => getHtmlOutput(page))
      .toContain('<p>1234567890</p>');
  });

  test('typing under maxLength is unaffected', async ({ page }) => {
    await gotoTestMaxLength(page);
    await setValue(page, '<html><p></p></html>');

    await focusEditor(page);
    await page.keyboard.type('12345', { delay: 20 });

    await expect
      .poll(async () => getHtmlOutput(page))
      .toContain('<p>12345</p>');
  });
});

test.describe('test-max-length pasting', () => {
  test.use({ permissions: ['clipboard-read', 'clipboard-write'] });

  test('pasting content that fits exactly is not truncated', async ({
    page,
  }) => {
    await gotoTestMaxLength(page);
    await setValue(page, '<html><p>1234567</p></html>');

    await copySelectionFrom(firstParagraph(page));

    await setValue(page, '<html><p></p></html>');
    await focusEditor(page);
    await page.keyboard.type('123', { delay: 20 });
    await pasteAtCurrentSelection(page);

    await expect
      .poll(async () => getHtmlOutput(page))
      .toContain('<p>1231234567</p>');
  });

  test('pasting into non-empty content truncates the pasted portion, keeping earlier text', async ({
    page,
  }) => {
    await gotoTestMaxLength(page);
    await setValue(page, '<html><p>1234567</p></html>');

    await copySelectionFrom(firstParagraph(page));

    await setValue(page, '<html><p>abcde</p></html>');
    await firstParagraph(page).click();
    await page.keyboard.press('End');
    await pasteAtCurrentSelection(page);

    await expect
      .poll(async () => getHtmlOutput(page))
      .toContain('<p>abcde12345</p>');
  });
});

test.describe('test-max-length mentions', () => {
  test('mention that fits entirely keeps its mark', async ({ page }) => {
    await gotoTestMaxLength(page);
    await setValue(page, '<html><p>123</p></html>');
    await setSelection(page, 4, 4);
    await page.keyboard.type(' ');
    await page.click(sel.startMentionButton);

    await page.fill(sel.mentionText, '@John');
    await page.click(sel.setMentionButton);

    await expect
      .poll(async () => getHtmlOutput(page))
      .toContain('<mention text="@John" indicator="@" id="1">@John</mention>');
  });

  test('mention overflowing maxLength is truncated and loses its mark', async ({
    page,
  }) => {
    await gotoTestMaxLength(page);
    await setValue(page, '<html><p>1234</p></html>');
    await setSelection(page, 4, 4);
    await page.waitForTimeout(100);
    await page.keyboard.type(' ');
    await page.click(sel.startMentionButton);

    await page.fill(sel.mentionText, '@Jonathan');
    await page.click(sel.setMentionButton);

    await expect
      .poll(async () => getHtmlOutput(page))
      .toContain('<p>1234 @Jona</p>');
    await expect
      .poll(async () => getHtmlOutput(page))
      .not.toContain('<mention');
  });
});

test.describe('test-max-length links', () => {
  test('manual link that fits entirely keeps its mark', async ({ page }) => {
    await gotoTestMaxLength(page);
    await setValue(page, '<html><p>123456</p></html>');

    await page.fill(sel.setLinkStart, '6');
    await page.fill(sel.setLinkEnd, '6');
    await page.fill(sel.setLinkText, 'ab');
    await page.fill(sel.setLinkUrl, 'https://example.com');
    await page.click(sel.applySetLink);

    await expect
      .poll(async () => getHtmlOutput(page))
      .toContain('<p>123456<a href="https://example.com">ab</a></p>');
  });

  test('manual link overflowing maxLength is truncated but keeps link styling', async ({
    page,
  }) => {
    await gotoTestMaxLength(page);
    await setValue(page, '<html><p>123456</p></html>');

    await page.fill(sel.setLinkStart, '6');
    await page.fill(sel.setLinkEnd, '6');
    await page.fill(sel.setLinkText, 'abcdefgh');
    await page.fill(sel.setLinkUrl, 'https://example.com');
    await page.click(sel.applySetLink);

    await expect
      .poll(async () => getHtmlOutput(page))
      .toContain('<a href="https://example.com">abcd</a>');
    await expect.poll(async () => getHtmlOutput(page)).not.toContain('efgh');
  });
});

test.describe('test-max-length images', () => {
  test('image that fits within maxLength is inserted', async ({ page }) => {
    await gotoTestMaxLength(page);
    await setValue(page, '<html><p>123456789</p></html>');

    await page.fill(sel.imageSrc, '/pw-e2e-ok.png');
    await page.fill(sel.imageWidth, '40');
    await page.fill(sel.imageHeight, '40');
    await page.click(sel.setImageButton);

    await expect
      .poll(async () => getHtmlOutput(page))
      .toContain('<img src="/pw-e2e-ok.png"');
  });

  test('image that would overflow maxLength is rejected entirely', async ({
    page,
  }) => {
    await gotoTestMaxLength(page);
    await setValue(page, '<html><p>1234567890</p></html>');

    await page.fill(sel.imageSrc, '/pw-e2e-ok.png');
    await page.fill(sel.imageWidth, '40');
    await page.fill(sel.imageHeight, '40');
    await page.click(sel.setImageButton);

    await page.waitForTimeout(200);
    await expect.poll(async () => getHtmlOutput(page)).not.toContain('<img');
    await expect
      .poll(async () => getHtmlOutput(page))
      .toContain('<p>1234567890</p>');
  });
});

test.describe('test-max-length replacing a selection with longer content', () => {
  test('pasting over a selection that would grow the doc past maxLength truncates the paste', async ({
    page,
  }) => {
    await gotoTestMaxLength(page);
    await setValue(page, '<html><p>overflowing-clip-source</p></html>');

    await copySelectionFrom(firstParagraph(page));

    await setValue(page, '<html><p>123xxx789</p></html>');
    // Select the "xxx" in the middle (positions 3..6).
    await setSelection(page, 3, 6);

    await pasteAtCurrentSelection(page);

    await expect.poll(async () => getHtmlOutput(page)).toContain('<p>123');
    const html = await getHtmlOutput(page);
    expect(html).toContain('789</p>');
    expect(html).not.toContain('overflowing-clip-source');
  });
});
