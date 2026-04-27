/**
 * @jest-environment jsdom
 */
import {
  nativeCheckboxHtmlToTiptapHtml,
  tiptapCheckboxListHtmlToNative,
} from '../checkboxListHtml';
import {
  normalizeHtmlFromTiptap,
  prepareHtmlForTiptap,
} from '../tiptapHtmlNormalizer';

type TableCase = {
  description: string;
  input: string;
  expected: string;
};

describe('nativeCheckboxHtmlToTiptapHtml', () => {
  const cases: TableCase[] = [
    {
      description: 'passthrough when no checkbox list',
      input: '<p>hello</p>',
      expected: '<p>hello</p>',
    },
    {
      description: 'converts ul checkbox to checkboxList and li attrs',
      input: '<ul data-type="checkbox"><li>one</li><li checked>two</li></ul>',
      expected:
        '<ul data-type="checkboxList"><li data-type="checkboxItem" data-checked="false"><p>one</p></li><li data-type="checkboxItem" data-checked="true"><p>two</p></li></ul>',
    },
  ];

  it.each(cases)('$description', ({ input, expected }) => {
    expect(nativeCheckboxHtmlToTiptapHtml(input)).toBe(expected);
  });
});

describe('tiptapCheckboxListHtmlToNative', () => {
  const cases: TableCase[] = [
    {
      description: 'passthrough when no checkboxList',
      input: '<p>x</p>',
      expected: '<p>x</p>',
    },
    {
      description:
        'converts checkboxList to native checkbox list (`li` / `li checked`, not data-checked)',
      input:
        '<ul data-type="checkboxList"><li data-type="checkboxItem" data-checked="false"><div><p>a</p></div></li><li data-type="checkboxItem" data-checked="true"><div><p>b</p></div></li></ul>',
      expected: '<ul data-type="checkbox"><li>a</li><li checked>b</li></ul>',
    },
  ];

  it.each(cases)('$description', ({ input, expected }) => {
    expect(tiptapCheckboxListHtmlToNative(input)).toBe(expected);
  });
});

describe('prepareHtmlForTiptap + normalizeHtmlFromTiptap (checkbox list)', () => {
  it('table: fake getHTML (checkboxList + div) in → normalized native html out', () => {
    const fakeTipTapGetHtml =
      '<ul data-type="checkboxList"><li data-type="checkboxItem" data-checked="false"><div><p>one</p></div></li><li data-type="checkboxItem" data-checked="true"><div><p>two</p></div></li></ul>';
    const out = normalizeHtmlFromTiptap(fakeTipTapGetHtml);
    expect(out).toBe(
      '<html><ul data-type="checkbox"><li>one</li><li checked>two</li></ul></html>'
    );
  });

  it('table: native checkbox html in → prepare matches expected checkboxList fragment', () => {
    const input =
      '<ul data-type="checkbox"><li>one</li><li checked>two</li></ul>';
    expect(prepareHtmlForTiptap(input)).toBe(
      '<ul data-type="checkboxList"><li data-type="checkboxItem" data-checked="false"><p>one</p></li><li data-type="checkboxItem" data-checked="true"><p>two</p></li></ul>'
    );
  });
});
