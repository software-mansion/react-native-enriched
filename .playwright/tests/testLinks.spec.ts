import { test, expect, type Page } from '@playwright/test';

import {
  editorLocator,
  getSerializedHtml,
  gotoVisualRegression,
  setEditorHtml,
} from '../helpers/visual-regression';

test.setTimeout(90_000);

const sel = {
  htmlInput: '[data-testid="test-links-html-input"]',
  setValueButton: '[data-testid="test-links-set-value-button"]',
  htmlOutput: '[data-testid="test-links-html-output"]',
  setLinkStart: '[data-testid="test-links-setlink-start"]',
  setLinkEnd: '[data-testid="test-links-setlink-end"]',
  setLinkText: '[data-testid="test-links-setlink-text"]',
  setLinkUrl: '[data-testid="test-links-setlink-url"]',
  applySetLink: '[data-testid="test-links-apply-setlink-button"]',
  selectionStart: '[data-testid="test-links-selection-start"]',
  selectionEnd: '[data-testid="test-links-selection-end"]',
  applySelection: '[data-testid="test-links-apply-selection-button"]',
  onLinkDetectedPayload: '[data-testid="on-link-detected-payload"]',
  editorInner: '[data-testid="test-links-editor"] .eti-editor',
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

test('links display visual regression', async ({ page }) => {
  await gotoVisualRegression(page);
  const html = [
    '<html>',
    '<p><a href="https://alpha.example">Alpha</a></p>',
    '<p>Plain between</p>',
    '<p><a href="https://omega.example">Omega</a></p>',
    '</html>',
  ].join('');
  await setEditorHtml(page, html);

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
    expectContains: string;
  }[] = [
    {
      name: 'wraps world with example.com',
      html: '<html><p>Hello world</p></html>',
      start: '6',
      end: '11',
      text: 'world',
      url: 'https://example.com',
      expectContains: '<p>Hello <a href="https://example.com">world</a></p>',
    },
    {
      name: 'wraps multiword phrase with spaces',
      html: '<html><p>one two three</p></html>',
      start: '4',
      end: '13',
      text: 'two three',
      url: 'https://multi.example',
      expectContains:
        '<p>one <a href="https://multi.example">two three</a></p>',
    },
    {
      name: 'inserts linked text at cursor when start and end are the same',
      html: '<html><p>xx</p></html>',
      start: '1',
      end: '1',
      text: 'm',
      url: 'https://same-range.example',
      expectContains: '<p>x<a href="https://same-range.example">m</a>x</p>',
    },
  ];

  for (const c of cases) {
    test(c.name, async ({ page }) => {
      await gotoTestLinks(page);
      await setTestLinksEditorHtml(page, c.html);

      await page.fill(sel.setLinkStart, c.start);
      await page.fill(sel.setLinkEnd, c.end);
      await page.fill(sel.setLinkText, c.text);
      await page.fill(sel.setLinkUrl, c.url);

      await page.click(sel.applySetLink);

      await expect
        .poll(async () => getTestLinksSerializedHtml(page))
        .toContain(c.expectContains);
    });
  }
});

test.describe('test-links onLinkDetected', () => {
  test('emits payload when selection is inside existing link', async ({
    page,
  }) => {
    await gotoTestLinks(page);
    await setTestLinksEditorHtml(
      page,
      `<html><p><a href="https://example.com">Example</a></p></html>`
    );

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

test.describe('test-links setLink with code', () => {
  test('splits inline code when setLink covers a sub-range: link replaces that segment, code on both sides', async ({
    page,
  }) => {
    await gotoTestLinks(page);
    await setTestLinksEditorHtml(
      page,
      '<html><p><code>A_inside_B</code></p></html>'
    );

    await expect
      .poll(async () => getTestLinksSerializedHtml(page))
      .toContain('A_inside_B');

    await page.fill(sel.setLinkStart, '1');
    await page.fill(sel.setLinkEnd, '9');
    await page.fill(sel.setLinkText, '_link_');
    await page.fill(sel.setLinkUrl, 'https://inline-split.test');
    await page.click(sel.applySetLink);

    const after = await getTestLinksSerializedHtml(page);
    expect(after).toContain('https://inline-split.test');
    expect(after).toContain(
      [
        '<p><code>A</code>',
        '<a href="https://inline-split.test">_link_</a>',
        '<code>B</code>',
        '</p>',
      ].join('')
    );
  });
});

test.describe('test-links setLink blocking', () => {
  test('does not add link when selection is in code block', async ({
    page,
  }) => {
    await gotoTestLinks(page);
    await setTestLinksEditorHtml(
      page,
      '<html><codeblock><p>line</p></codeblock></html>'
    );

    await expect
      .poll(async () => getTestLinksSerializedHtml(page))
      .toContain('line');

    const before = await getTestLinksSerializedHtml(page);

    await page.locator('.eti-editor codeblock p').click();

    await page.fill(sel.setLinkStart, '0');
    await page.fill(sel.setLinkEnd, '4');
    await page.fill(sel.setLinkText, 'line');
    await page.fill(sel.setLinkUrl, 'https://blocked-block.test');
    await page.click(sel.applySetLink);

    const after = await getTestLinksSerializedHtml(page);
    expect(after).toBe(before);
    expect(after).not.toContain('<a>');
    expect(after).toContain('<codeblock><p>line</p></codeblock>');
  });
});
