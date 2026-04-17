import { test, expect, type Page } from '@playwright/test';

import {
  editorLocator,
  getSerializedHtml,
  gotoVisualRegression,
  setEditorHtml,
} from '../helpers/visual-regression';

test.setTimeout(90_000);

const LINKS_VISUAL_HTML = [
  '<html>',
  '<p><a href="https://alpha.example">Alpha</a></p>',
  '<p>Plain between</p>',
  '<p><a href="https://omega.example">Omega</a></p>',
  '</html>',
].join('');

const sel = {
  htmlInput: '[data-testid="test-links-html-input"]',
  setValueButton: '[data-testid="test-links-set-value-button"]',
  htmlOutput: '[data-testid="test-links-html-output"]',
  setlinkStart: '[data-testid="test-links-setlink-start"]',
  setlinkEnd: '[data-testid="test-links-setlink-end"]',
  setlinkText: '[data-testid="test-links-setlink-text"]',
  setlinkUrl: '[data-testid="test-links-setlink-url"]',
  applySetLink: '[data-testid="test-links-apply-setlink-button"]',
  selectionStart: '[data-testid="test-links-selection-start"]',
  selectionEnd: '[data-testid="test-links-selection-end"]',
  applySelection: '[data-testid="test-links-apply-selection-button"]',
  onLinkDetectedPayload: '[data-testid="on-link-detected-payload"]',
  editorInner: '[data-testid="test-links-editor"] .eti-editor',
  /** Wrapper has fixed width; `.eti-editor` bbox can span the viewport — screenshot this instead. */
  editorScreenshot: '[data-testid="test-links-editor"]',
} as const;

async function gotoTestLinks(page: Page): Promise<void> {
  await page.goto('/test-links');
  await page.waitForSelector(sel.editorInner);
}

async function getTestLinksSerializedHtml(page: Page): Promise<string> {
  return (await page.locator(sel.htmlOutput).textContent()) ?? '';
}

async function setTestLinksEditorHtml(page: Page, html: string): Promise<void> {
  await page.fill(sel.htmlInput, html);
  await page.click(sel.setValueButton);
  await expect
    .poll(async () => {
      const t = await getTestLinksSerializedHtml(page);
      return t.startsWith('<html>');
    })
    .toBe(true);
}

async function getOnLinkDetectedPayload(page: Page): Promise<string> {
  return (await page.locator(sel.onLinkDetectedPayload).textContent()) ?? '';
}

const PLAIN_HELLO = '<html><p>Hello world</p></html>';
const SINGLE_LINK = `<html><p><a href="https://example.com">Example</a></p></html>`;
const INLINE_CODE = '<html><p><code>inside</code></p></html>';
const CODEBLOCK = '<html><codeblock><p>line</p></codeblock></html>';

test('links display visual regression', async ({ page }) => {
  await gotoVisualRegression(page);
  await setEditorHtml(page, LINKS_VISUAL_HTML);

  await expect(editorLocator(page)).toHaveScreenshot('links-display.png');
});

test('link mark round-trips in serialized HTML', async ({ page }) => {
  await gotoVisualRegression(page);
  await setEditorHtml(
    page,
    '<html><p><a href="https://example.com">Example</a></p></html>'
  );

  await expect
    .poll(async () => getSerializedHtml(page))
    .toContain('<a href="https://example.com">Example</a>');
});

test.describe('test-links setLink table', () => {
  const cases: {
    name: string;
    html: string;
    start: string;
    end: string;
    text: string;
    url: string;
    /** Full `<a href="...">...</a>` substring expected in serialized HTML. */
    expectContains: string;
  }[] = [
    {
      name: 'wraps world with example.com',
      html: PLAIN_HELLO,
      start: '6',
      end: '11',
      text: 'world',
      url: 'https://example.com',
      expectContains: '<a href="https://example.com">world</a>',
    },
    {
      name: 'wraps Hello with second host',
      html: PLAIN_HELLO,
      start: '0',
      end: '5',
      text: 'Hello',
      url: 'https://hello.example',
      expectContains: '<a href="https://hello.example">Hello</a>',
    },
    {
      name: 'wraps multiword phrase with spaces',
      html: '<html><p>one two three</p></html>',
      start: '4',
      end: '13',
      text: 'two three',
      url: 'https://multi.example',
      expectContains: '<a href="https://multi.example">two three</a>',
    },
  ];

  for (const c of cases) {
    test(c.name, async ({ page }) => {
      await gotoTestLinks(page);
      await setTestLinksEditorHtml(page, c.html);

      await page.fill(sel.setlinkStart, c.start);
      await page.fill(sel.setlinkEnd, c.end);
      await page.fill(sel.setlinkText, c.text);
      await page.fill(sel.setlinkUrl, c.url);

      await page.click(sel.applySetLink);

      await expect
        .poll(async () => getTestLinksSerializedHtml(page))
        .toContain(c.expectContains);
    });
  }
});

test('test-links imperative setLink visual regression', async ({ page }) => {
  await gotoTestLinks(page);
  await setTestLinksEditorHtml(page, '<html><p>one two three</p></html>');

  await page.fill(sel.setlinkStart, '4');
  await page.fill(sel.setlinkEnd, '13');
  await page.fill(sel.setlinkText, 'two three');
  await page.fill(sel.setlinkUrl, 'https://multi.example');
  await page.click(sel.applySetLink);

  await expect
    .poll(async () => getTestLinksSerializedHtml(page))
    .toContain('<a href="https://multi.example">two three</a>');

  await expect(page.locator(sel.editorScreenshot)).toHaveScreenshot(
    'test-links-setlink.png'
  );
});

test.describe('test-links onLinkDetected', () => {
  test('emits payload when selection is inside existing link', async ({
    page,
  }) => {
    await gotoTestLinks(page);
    await setTestLinksEditorHtml(page, SINGLE_LINK);

    await page.fill(sel.selectionStart, '0');
    await page.fill(sel.selectionEnd, '7');
    await page.click(sel.applySelection);

    await expect
      .poll(async () => getOnLinkDetectedPayload(page))
      .toContain('https://example.com');
    await expect
      .poll(async () => getOnLinkDetectedPayload(page))
      .toContain('"text":"Example"');
  });
});

test.describe('test-links setLink blocking', () => {
  test('does not add link when selection is in inline code', async ({
    page,
  }) => {
    await gotoTestLinks(page);
    await setTestLinksEditorHtml(page, INLINE_CODE);

    await expect
      .poll(async () => getTestLinksSerializedHtml(page))
      .toContain('inside');

    const before = await getTestLinksSerializedHtml(page);

    await page.fill(sel.selectionStart, '0');
    await page.fill(sel.selectionEnd, '5');
    await page.click(sel.applySelection);

    await page.fill(sel.setlinkStart, '0');
    await page.fill(sel.setlinkEnd, '5');
    await page.fill(sel.setlinkText, 'inside');
    await page.fill(sel.setlinkUrl, 'https://blocked-inline.test');
    await page.click(sel.applySetLink);

    const after = await getTestLinksSerializedHtml(page);
    expect(after).toBe(before);
    expect(after).not.toContain('blocked-inline.test');
  });

  test('does not add link when selection is in code block', async ({
    page,
  }) => {
    await gotoTestLinks(page);
    await setTestLinksEditorHtml(page, CODEBLOCK);

    await expect
      .poll(async () => getTestLinksSerializedHtml(page))
      .toContain('line');

    const before = await getTestLinksSerializedHtml(page);

    await page.locator('.eti-editor codeblock p').click();

    await page.fill(sel.setlinkStart, '0');
    await page.fill(sel.setlinkEnd, '4');
    await page.fill(sel.setlinkText, 'line');
    await page.fill(sel.setlinkUrl, 'https://blocked-block.test');
    await page.click(sel.applySetLink);

    const after = await getTestLinksSerializedHtml(page);
    expect(after).toBe(before);
    expect(after).not.toContain('blocked-block.test');
  });
});
