import { test, expect, type Page } from '@playwright/test';

import { toolbarButton } from '../helpers/toolbar';
import {
  getSerializedHtml,
  gotoVisualRegression,
  setEditorHtml,
} from '../helpers/visual-regression';

function hasOpeningTag(html: string, tag: string): boolean {
  return new RegExp(`<${tag}(?:\\s|>)`, 'i').test(html);
}

async function waitForOpeningTagInSerializedHtml(
  page: Page,
  tag: string
): Promise<void> {
  await expect
    .poll(async () => hasOpeningTag(await getSerializedHtml(page), tag))
    .toBe(true);
}

type ToolbarKey = 'h1' | 'h2' | 'h3' | 'blockQuote' | 'codeBlock';

const CASES: readonly {
  name: string;
  html: string;
  focusSelector: string;
  click: ToolbarKey;
  expectTag: string;
  notTags: readonly string[];
  expectText: string;
}[] = [
  {
    name: 'h1 → blockquote',
    html: '<html><h1>Heading</h1></html>',
    focusSelector: '.eti-editor h1',
    click: 'blockQuote',
    expectTag: 'blockquote',
    notTags: ['h1'],
    expectText: 'Heading',
  },
  {
    name: 'h1 → codeblock',
    html: '<html><h1>Heading</h1></html>',
    focusSelector: '.eti-editor h1',
    click: 'codeBlock',
    expectTag: 'codeblock',
    notTags: ['h1'],
    expectText: 'Heading',
  },
  {
    name: 'h2 → blockquote',
    html: '<html><h2>Heading</h2></html>',
    focusSelector: '.eti-editor h2',
    click: 'blockQuote',
    expectTag: 'blockquote',
    notTags: ['h2'],
    expectText: 'Heading',
  },
  {
    name: 'blockquote → h1',
    html: '<html><blockquote><p>Quote</p></blockquote></html>',
    focusSelector: '.eti-editor blockquote p',
    click: 'h1',
    expectTag: 'h1',
    notTags: ['blockquote'],
    expectText: 'Quote',
  },
  {
    name: 'codeblock → blockquote',
    html: '<html><codeblock><p>Code</p></codeblock></html>',
    focusSelector: '.eti-editor codeblock p',
    click: 'blockQuote',
    expectTag: 'blockquote',
    notTags: ['codeblock'],
    expectText: 'Code',
  },
  {
    name: 'blockquote → codeblock',
    html: '<html><blockquote><p>Quote</p></blockquote></html>',
    focusSelector: '.eti-editor blockquote p',
    click: 'codeBlock',
    expectTag: 'codeblock',
    notTags: ['blockquote'],
    expectText: 'Quote',
  },
  {
    name: 'h1 → h2 (heading swap)',
    html: '<html><h1>Heading</h1></html>',
    focusSelector: '.eti-editor h1',
    click: 'h2',
    expectTag: 'h2',
    notTags: ['h1'],
    expectText: 'Heading',
  },
  {
    name: 'h3 → blockquote',
    html: '<html><h3>Heading</h3></html>',
    focusSelector: '.eti-editor h3',
    click: 'blockQuote',
    expectTag: 'blockquote',
    notTags: ['h3'],
    expectText: 'Heading',
  },
];

test.describe('conflicting block styles (toolbar replaces active block)', () => {
  test.beforeEach(async ({ page }) => {
    await gotoVisualRegression(page);
  });

  for (const {
    name,
    html,
    focusSelector,
    click: toolbarKey,
    expectTag,
    notTags,
    expectText,
  } of CASES) {
    test(name, async ({ page }) => {
      await setEditorHtml(page, html);

      await page.locator(focusSelector).click();
      await toolbarButton(page, toolbarKey).click();

      await waitForOpeningTagInSerializedHtml(page, expectTag);

      const out = await getSerializedHtml(page);
      for (const t of notTags) {
        expect(hasOpeningTag(out, t)).toBe(false);
      }
      expect(out).toContain(expectText);
    });
  }
});
