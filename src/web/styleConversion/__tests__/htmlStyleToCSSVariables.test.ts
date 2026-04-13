import type { CSSProperties } from 'react';
import type { HtmlStyle } from '../../../types';
import { DEFAULT_HTML_STYLE } from '../../../utils/defaultHtmlStyle';
import {
  htmlStyleToCSSVariables,
  mergeWithDefaultHtmlStyle,
} from '../htmlStyleToCSSVariables';

type CodeStyle = HtmlStyle['code'];

describe('mergeWithDefaultHtmlStyle', () => {
  const cases: Array<[HtmlStyle | undefined, Partial<Required<HtmlStyle>>]> = [
    [undefined, DEFAULT_HTML_STYLE],
    [{}, DEFAULT_HTML_STYLE],
    [
      { code: { color: 'purple' } },
      {
        code: {
          color: 'purple',
          backgroundColor: DEFAULT_HTML_STYLE.code.backgroundColor,
        },
      },
    ],
    [
      { code: { color: 'purple', backgroundColor: 'white' } },
      { code: { color: 'purple', backgroundColor: 'white' } },
    ],
    [
      { h1: { fontSize: 48 } },
      { h1: { fontSize: 48, bold: DEFAULT_HTML_STYLE.h1.bold } },
    ],
    [
      { ul: { bulletColor: 'red' } },
      {
        ul: {
          bulletColor: 'red',
          bulletSize: DEFAULT_HTML_STYLE.ul.bulletSize,
          marginLeft: DEFAULT_HTML_STYLE.ul.marginLeft,
          gapWidth: DEFAULT_HTML_STYLE.ul.gapWidth,
        },
      },
    ],
  ];

  it.each(cases)('%j → contains %j', (input, expected) => {
    expect(mergeWithDefaultHtmlStyle(input)).toMatchObject(expected);
  });
});

describe('htmlStyleToCSSVariables', () => {
  it('returns empty object for undefined input', () => {
    expect(htmlStyleToCSSVariables(undefined)).toEqual({});
  });

  it('returns empty object for empty style', () => {
    expect(htmlStyleToCSSVariables({})).toEqual({});
  });

  it('integer color → rgba string', () => {
    const input = { code: { color: 0xff0000ff as unknown as string } };
    expect(htmlStyleToCSSVariables(input)).toEqual({
      '--eti-code-color': 'rgba(255, 0, 0, 1)',
    } as CSSProperties);
  });

  describe('code styles', () => {
    const cases = [
      [{ color: '#ff0000' }, { '--eti-code-color': '#ff0000' }],
      [
        { color: 'rgba(0,128,255,1)' },
        { '--eti-code-color': 'rgba(0,128,255,1)' },
      ],
      [{ backgroundColor: '#f5f5f5' }, { '--eti-code-bg-color': '#f5f5f5' }],
      [
        { color: '#333', backgroundColor: '#f5f5f5' },
        { '--eti-code-color': '#333', '--eti-code-bg-color': '#f5f5f5' },
      ],
      [{}, {}],
      [undefined, {}],
    ] as Array<[CodeStyle, CSSProperties]>;

    it.each(cases)('%j → %j', (code, expected) => {
      expect(htmlStyleToCSSVariables({ code })).toEqual(expected);
    });
  });
});
