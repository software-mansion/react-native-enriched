import { test, expect, type Page } from '@playwright/test';

import {
  editorLocator,
  getSerializedHtml,
  gotoVisualRegression,
  setEditorHtml,
} from '../helpers/visual-regression';
import { pastePlainTextIntoEditor } from '../helpers/clipboard';

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
  removeLinkStart: '[data-testid="test-links-removelink-start"]',
  removeLinkEnd: '[data-testid="test-links-removelink-end"]',
  applyRemoveLink: '[data-testid="test-links-apply-removelink-button"]',
  selectionStart: '[data-testid="test-links-selection-start"]',
  selectionEnd: '[data-testid="test-links-selection-end"]',
  applySelection: '[data-testid="test-links-apply-selection-button"]',
  onLinkDetectedPayload: '[data-testid="on-link-detected-payload"]',
  editorInner: '[data-testid="test-links-editor"] .eti-editor',
  editorScreenshot: '[data-testid="test-links-editor"]',
  linkRegexMode: '[data-testid="test-links-link-regex-mode"]',
  linkRegexPattern: '[data-testid="test-links-link-regex-pattern"]',
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
    {
      name: 'setLink blocked when selection entirely in codeblock',
      html: '<html><codeblock><p>line</p></codeblock></html>',
      start: '0',
      end: '4',
      text: 'line',
      url: 'https://blocked-block.test',
      expectContains: '<html><codeblock><p>line</p></codeblock></html>',
    },
    {
      name: 'setLink blocked when selection partially in codeblock',
      html: '<html><codeblock><p>line</p></codeblock><p>suffix</p></html>',
      start: '0',
      end: '10',
      text: 'line',
      url: 'https://blocked-block.test',
      expectContains:
        '<html><codeblock><p>line</p></codeblock><p>suffix</p></html>',
    },
    {
      name: 'setLink blocked when selection entirely in code',
      html: '<html><p><code>line</code></p></html>',
      start: '0',
      end: '4',
      text: 'line',
      url: 'https://blocked-block.test',
      expectContains: '<html><p><code>line</code></p></html>',
    },
    {
      name: 'setLink blocked when selection partially in code',
      html: '<html><p><code>line</code> suffix</p></html>',
      start: '2',
      end: '10',
      text: 'line',
      url: 'https://blocked-block.test',
      expectContains: '<html><p><code>line</code> suffix</p></html>',
    },
    {
      name: 'setLink clamps out-of-bounds start/end to document range',
      html: '<html><p>Hello world</p></html>',
      start: '0',
      end: '99999',
      text: 'Z',
      url: 'https://clamp.setlink',
      expectContains: '<p><a href="https://clamp.setlink">Z</a></p>',
    },
    {
      name: 'setLink wraps link text before inline image - keeps the image',
      html: '<html><p>abc<img width="80" height="80" src=""></p></html>',
      start: '0',
      end: '3',
      text: 'abc',
      url: 'https://example.com',
      expectContains:
        '<p><a href="https://example.com">abc</a><img src="" width="80" height="80"/></p>',
    },
    {
      name: 'wraps bold italic list item text with link',
      html: '<html><ul><li><b><i>styled</i></b></li><li>hello</li></ul></html>',
      start: '0',
      end: '6',
      text: 'styled',
      url: 'https://list-styled.example',
      expectContains:
        '<ul><li><a href="https://list-styled.example"><b><i>styled</i></b></a></li><li>hello</li></ul>',
    },
    {
      name: 'inserts linked text at cursor at very start of first list item',
      html: '<html><ul><li>first</li><li>second</li></ul></html>',
      start: '0',
      end: '0',
      text: 'Link',
      url: 'https://cursor-list.example',
      expectContains:
        '<ul><li><a href="https://cursor-list.example">Link</a>first</li><li>second</li></ul>',
    },
    {
      name: 'inserts linked text at cursor inside empty list item',
      html: '<html><ul><li></li></ul></html>',
      start: '0',
      end: '0',
      text: 'Link',
      url: 'https://empty-list.example',
      expectContains:
        '<ul><li><a href="https://empty-list.example">Link</a></li></ul>',
    },
    {
      name: 'wraps mixed bold and bold-italic text in list item with link as outermost mark',
      html: '<html><ul><li><b>ab<i>cd</i></b></li></ul></html>',
      start: '0',
      end: '4',
      text: 'abcd',
      url: 'https://mixed-marks.example',
      expectContains:
        '<ul><li><a href="https://mixed-marks.example"><b>ab<i>cd</i></b></a></li></ul>',
    },
    {
      name: 'setLink replacement longer than selection applies marks from range start only',
      html: '<html><ul><li><b>ab<i>cd</i></b></li></ul></html>',
      start: '0',
      end: '4',
      text: 'abcdef',
      url: 'https://mixed-marks-longer.example',
      expectContains:
        '<ul><li><a href="https://mixed-marks-longer.example"><b>abcdef</b></a></li></ul>',
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

test.describe('test-links removeLink table', () => {
  const cases: {
    name: string;
    html: string;
    start: string;
    end: string;
    expectContains: string;
  }[] = [
    {
      name: 'entire link removal',
      html: '<html><p>Hello <a href="https://example.com">world</a></p></html>',
      start: '6',
      end: '11',
      expectContains: '<p>Hello world</p>',
    },
    {
      name: 'partial removal: 2 of 5 link chars unlinked, rest stays linked',
      html: '<html><p><a href="https://partial.test">abcde</a></p></html>',
      start: '0',
      end: '2',
      expectContains: '<p>ab<a href="https://partial.test">cde</a></p>',
    },
    {
      name: 'no link: plain paragraph unchanged',
      html: '<html><p>Hello world</p></html>',
      start: '0',
      end: '11',
      expectContains: '<p>Hello world</p>',
    },
    {
      name: 'removeLink clamps end past document; unlinks full range',
      html: '<html><p><a href="https://clamp.rm">ab</a></p></html>',
      start: '0',
      end: '9999',
      expectContains: '<p>ab</p>',
    },
    {
      name: 'removeLink clamps both past doc; selection at end outside link, link unchanged',
      html: '<html><p>prefix <a href="https://noop.rm">ab</a> tail</p></html>',
      start: '1000',
      end: '1000',
      expectContains: '<a href="https://noop.rm">ab</a>',
    },
  ];

  for (const c of cases) {
    test(c.name, async ({ page }) => {
      await gotoTestLinks(page);
      await setTestLinksEditorHtml(page, c.html);

      await page.fill(sel.removeLinkStart, c.start);
      await page.fill(sel.removeLinkEnd, c.end);
      await page.click(sel.applyRemoveLink);

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

  test('emits empty text and url with when selection leaves a link', async ({
    page,
  }) => {
    await gotoTestLinks(page);
    await setTestLinksEditorHtml(
      page,
      `<html><p><a href="https://example.com">Example</a></p></html>`
    );

    const editor = page.locator(sel.editorInner);
    await editor.click();
    await expect(editor.locator('.ProseMirror')).toBeFocused();
    await editor.press('End');
    await editor.press('Enter');

    await expect
      .poll(async () => JSON.parse(await getOnLinkDetectedPayload(page)) as any)
      .toEqual({
        text: '',
        url: '',
        start: 0,
        end: 0,
      });
  });
});

test.describe('test-links autolink', () => {
  async function resetEditorAndSetLinkRegexMode(
    page: Page,
    mode: 'default' | 'disabled' | 'custom'
  ): Promise<void> {
    await gotoTestLinks(page);
    await page.locator(sel.linkRegexMode).selectOption(mode);
    await setTestLinksEditorHtml(page, '<html><p></p></html>');
  }

  test('creates link while typing with default URL regex', async ({ page }) => {
    await resetEditorAndSetLinkRegexMode(page, 'default');

    const editor = page.locator(sel.editorInner);
    await editor.click();
    await expect(editor.locator('.ProseMirror')).toBeFocused();
    await page.keyboard.type('Visit https://example.com');

    await expect
      .poll(async () => getTestLinksSerializedHtml(page))
      .toContain('<a href="https://example.com">https://example.com</a>');
  });

  test('creates link while typing with custom regex', async ({ page }) => {
    await gotoTestLinks(page);
    await page.locator(sel.linkRegexMode).selectOption('custom');
    await page.fill(sel.linkRegexPattern, String.raw`issue-\d+`);
    await setTestLinksEditorHtml(page, '<html><p></p></html>');

    const editor = page.locator(sel.editorInner);
    await editor.click();
    await expect(editor.locator('.ProseMirror')).toBeFocused();
    await page.keyboard.type('tick issue-123 done');

    await expect
      .poll(async () => getTestLinksSerializedHtml(page))
      .toContain('<a href="issue-123">issue-123</a>');
  });

  test('creates link when pasting plain URL with default regex', async ({
    page,
  }) => {
    await resetEditorAndSetLinkRegexMode(page, 'default');

    await pastePlainTextIntoEditor(
      page.locator(sel.editorInner),
      'https://example.com'
    );

    await expect
      .poll(async () => getTestLinksSerializedHtml(page))
      .toContain('<a href="https://example.com">https://example.com</a>');
  });

  test('does not autolink when link regex is disabled', async ({ page }) => {
    await resetEditorAndSetLinkRegexMode(page, 'disabled');

    const editor = page.locator(sel.editorInner);
    await editor.click();
    await expect(editor.locator('.ProseMirror')).toBeFocused();
    await page.keyboard.type('https://example.com');

    await expect
      .poll(async () => getTestLinksSerializedHtml(page))
      .not.toContain('<a href');
  });
});
