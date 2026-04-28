import { test, expect, type Page } from '@playwright/test';

import { toolbarButton } from '../helpers/toolbar';
import {
  editorLocator,
  getSerializedHtml,
  gotoVisualRegression,
  setEditorHtml,
} from '../helpers/visual-regression';

function hasOpeningTag(html: string, tag: string): boolean {
  return new RegExp(`<${tag}(?:\\s|>)`, 'i').test(html);
}

/** Collapses whitespace between tags; keeps spaces inside attributes/text. */
function compactHtml(html: string): string {
  return html.replace(/>\s+</g, '><').trim();
}

async function waitForOpeningTagInSerializedHtml(
  page: Page,
  tag: string
): Promise<void> {
  await expect
    .poll(async () => hasOpeningTag(await getSerializedHtml(page), tag))
    .toBe(true);
}

type ToolbarKey =
  | 'h1'
  | 'h2'
  | 'h3'
  | 'blockQuote'
  | 'codeBlock'
  | 'unorderedList'
  | 'orderedList'
  | 'checkboxList';

test.describe('conflicting block styles (toolbar replaces active block)', () => {
  test.beforeEach(async ({ page }) => {
    await gotoVisualRegression(page);
  });

  const cases: readonly {
    name: string;
    html: string;
    focusSelector: string;
    click: ToolbarKey;
    expectTag: string;
    expectText: string;
  }[] = [
    {
      name: 'h1 → blockquote',
      html: '<html><h1>Heading</h1></html>',
      focusSelector: '.eti-editor h1',
      click: 'blockQuote',
      expectTag: 'blockquote',
      expectText: 'Heading',
    },
    {
      name: 'h1 → codeblock',
      html: '<html><h1>Heading</h1></html>',
      focusSelector: '.eti-editor h1',
      click: 'codeBlock',
      expectTag: 'codeblock',
      expectText: 'Heading',
    },
    {
      name: 'h2 → blockquote',
      html: '<html><h2>Heading</h2></html>',
      focusSelector: '.eti-editor h2',
      click: 'blockQuote',
      expectTag: 'blockquote',
      expectText: 'Heading',
    },
    {
      name: 'blockquote → h1',
      html: '<html><blockquote><p>Quote</p></blockquote></html>',
      focusSelector: '.eti-editor blockquote p',
      click: 'h1',
      expectTag: 'h1',
      expectText: 'Quote',
    },
    {
      name: 'codeblock → blockquote',
      html: '<html><codeblock><p>Code</p></codeblock></html>',
      focusSelector: '.eti-editor codeblock p',
      click: 'blockQuote',
      expectTag: 'blockquote',
      expectText: 'Code',
    },
    {
      name: 'blockquote → codeblock',
      html: '<html><blockquote><p>Quote</p></blockquote></html>',
      focusSelector: '.eti-editor blockquote p',
      click: 'codeBlock',
      expectTag: 'codeblock',
      expectText: 'Quote',
    },
    {
      name: 'h1 → h2 (heading swap)',
      html: '<html><h1>Heading</h1></html>',
      focusSelector: '.eti-editor h1',
      click: 'h2',
      expectTag: 'h2',
      expectText: 'Heading',
    },
    {
      name: 'h3 → blockquote',
      html: '<html><h3>Heading</h3></html>',
      focusSelector: '.eti-editor h3',
      click: 'blockQuote',
      expectTag: 'blockquote',
      expectText: 'Heading',
    },
    {
      name: 'h1 → unordered list',
      html: '<html><h1>Heading</h1></html>',
      focusSelector: '.eti-editor h1',
      click: 'unorderedList',
      expectTag: 'ul',
      expectText: 'Heading',
    },
    {
      name: 'h1 → ordered list',
      html: '<html><h1>Heading</h1></html>',
      focusSelector: '.eti-editor h1',
      click: 'orderedList',
      expectTag: 'ol',
      expectText: 'Heading',
    },
    {
      name: 'blockquote → unordered list',
      html: '<html><blockquote><p>Quote</p></blockquote></html>',
      focusSelector: '.eti-editor blockquote p',
      click: 'unorderedList',
      expectTag: 'ul',
      expectText: 'Quote',
    },
    {
      name: 'codeblock → unordered list',
      html: '<html><codeblock><p>Code</p></codeblock></html>',
      focusSelector: '.eti-editor codeblock p',
      click: 'unorderedList',
      expectTag: 'ul',
      expectText: 'Code',
    },
    {
      name: 'unordered list → h2',
      html: '<html><ul><li>Item</li></ul></html>',
      focusSelector: '.eti-editor ul li p',
      click: 'h2',
      expectTag: 'h2',
      expectText: 'Item',
    },
    {
      name: 'ordered list → h2',
      html: '<html><ol><li>Item</li></ol></html>',
      focusSelector: '.eti-editor ol li p',
      click: 'h2',
      expectTag: 'h2',
      expectText: 'Item',
    },
    {
      name: 'checkbox list -> h2',
      html: '<html><ul data-type="checkbox"><li>Item</li></ul></html>',
      focusSelector: '.eti-editor ul[data-type="checkboxList"] li p',
      click: 'h2',
      expectTag: 'h2',
      expectText: 'Item',
    },
    {
      name: 'blockquote -> checkbox list',
      html: '<html><blockquote><p>Quote</p></blockquote></html>',
      focusSelector: '.eti-editor blockquote p',
      click: 'checkboxList',
      expectTag: 'ul data-type="checkbox"',
      expectText: 'Quote',
    },
  ];

  for (const {
    name,
    html,
    focusSelector,
    click: toolbarKey,
    expectTag,
    expectText,
  } of cases) {
    test(name, async ({ page }) => {
      await setEditorHtml(page, html);

      await page.locator(focusSelector).click();
      await toolbarButton(page, toolbarKey).click();

      await waitForOpeningTagInSerializedHtml(page, expectTag);

      const out = await getSerializedHtml(page);
      expect(out).toContain(expectText);
    });
  }
});

test.describe('mixed top-level block selection (expand then toggle)', () => {
  test.beforeEach(async ({ page }) => {
    await gotoVisualRegression(page);
  });

  type MixedCase = {
    name: string;
    html: string;
    click: ToolbarKey;
    expectTag: string;
    expectHtmlSnippet: string;
  };

  const cases: readonly MixedCase[] = [
    {
      name: 'p + blockquote → single blockquote (blockQuote)',
      html: '<html><p>Left</p><blockquote><p>Right</p></blockquote></html>',
      click: 'blockQuote',
      expectTag: 'blockquote',
      expectHtmlSnippet: '<blockquote><p>Left</p><p>Right</p></blockquote>',
    },
    {
      name: 'p + codeblock → single codeblock (codeBlock)',
      html: '<html><p>Left</p><codeblock><p>Right</p></codeblock></html>',
      click: 'codeBlock',
      expectTag: 'codeblock',
      expectHtmlSnippet: '<codeblock><p>Left</p><p>Right</p></codeblock>',
    },
    {
      name: 'p + h2 → h1 across both (h1)',
      html: '<html><p>Left</p><h2>Right</h2></html>',
      click: 'h1',
      expectTag: 'h1',
      expectHtmlSnippet: '<h1>Left</h1><h1>Right</h1>',
    },
  ];

  for (const {
    name,
    html,
    click: toolbarKey,
    expectTag,
    expectHtmlSnippet,
  } of cases) {
    test(name, async ({ page }) => {
      await setEditorHtml(page, html);

      const ed = editorLocator(page);
      await ed.getByText('Left').click();
      await ed.getByText('Right').click({ modifiers: ['Shift'] });

      await toolbarButton(page, toolbarKey).click();

      await waitForOpeningTagInSerializedHtml(page, expectTag);

      const out = compactHtml(await getSerializedHtml(page));
      expect(out).toContain(expectHtmlSnippet);
    });
  }
});
