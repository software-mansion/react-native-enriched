import type { CSSProperties } from 'react';
import type { HtmlStyle, MentionStyleProperties } from '../../../types';
import { DEFAULT_HTML_STYLE } from '../../../utils/defaultHtmlStyle';
import {
  htmlStyleToCSSVariables,
  mergeWithDefaultHtmlStyle,
} from '../htmlStyleToCSSVariables';

type CodeStyle = HtmlStyle['code'];

const DEFAULT_MENTION_CSS_VARS: Record<string, string> = {
  '--eti-mention-default-color': String(DEFAULT_HTML_STYLE.mention.color),
  '--eti-mention-default-background-color': String(
    DEFAULT_HTML_STYLE.mention.backgroundColor
  ),
  '--eti-mention-default-text-decoration-line': String(
    DEFAULT_HTML_STYLE.mention.textDecorationLine
  ),
};

const defaultMentionOnlyResolved = {
  default: { ...DEFAULT_HTML_STYLE.mention },
};

describe('mergeWithDefaultHtmlStyle', () => {
  it('undefined → default mention key', () => {
    expect(mergeWithDefaultHtmlStyle(undefined)).toMatchObject({
      ...DEFAULT_HTML_STYLE,
      mention: defaultMentionOnlyResolved,
    });
  });

  it('{} → default mention key', () => {
    expect(mergeWithDefaultHtmlStyle({})).toMatchObject({
      ...DEFAULT_HTML_STYLE,
      mention: defaultMentionOnlyResolved,
    });
  });

  it('flat mention → default key only', () => {
    expect(
      mergeWithDefaultHtmlStyle({ mention: { color: 'purple' } }).mention
    ).toEqual({
      default: { ...DEFAULT_HTML_STYLE.mention, color: 'purple' },
    });
  });

  it('mention: default key + @', () => {
    const m = mergeWithDefaultHtmlStyle({
      mention: {
        'default': { backgroundColor: 'white' },
        '@': { color: 'red' },
      },
    }).mention as Record<string, MentionStyleProperties>;
    expect(m.default).toMatchObject({
      ...DEFAULT_HTML_STYLE.mention,
      backgroundColor: 'white',
    });
    expect(m['@']).toMatchObject({
      ...DEFAULT_HTML_STYLE.mention,
      color: 'red',
      backgroundColor: DEFAULT_HTML_STYLE.mention.backgroundColor,
    });
  });

  const cases: Array<[HtmlStyle, Partial<Required<HtmlStyle>>]> = [
    [
      { code: { color: 'purple' } },
      {
        mention: defaultMentionOnlyResolved,
        code: {
          color: 'purple',
          backgroundColor: DEFAULT_HTML_STYLE.code.backgroundColor,
        },
      },
    ],
    [
      { code: { color: 'purple', backgroundColor: 'white' } },
      {
        mention: defaultMentionOnlyResolved,
        code: { color: 'purple', backgroundColor: 'white' },
      },
    ],
    [
      { h1: { fontSize: 48 } },
      {
        mention: defaultMentionOnlyResolved,
        h1: { fontSize: 48, bold: DEFAULT_HTML_STYLE.h1.bold },
      },
    ],
    [
      { ul: { bulletColor: 'red' } },
      {
        mention: defaultMentionOnlyResolved,
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
  it('undefined → default mention vars only', () => {
    expect(htmlStyleToCSSVariables(undefined)).toEqual(
      DEFAULT_MENTION_CSS_VARS as CSSProperties
    );
  });

  it('empty style → default mention vars only', () => {
    expect(htmlStyleToCSSVariables({})).toEqual(
      DEFAULT_MENTION_CSS_VARS as CSSProperties
    );
  });

  it('integer color → rgba string', () => {
    const input = { code: { color: 0xff0000ff as unknown as string } };
    expect(htmlStyleToCSSVariables(input)).toMatchObject({
      '--eti-code-color': 'rgba(255, 0, 0, 1)',
    });
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
    ] as Array<[CodeStyle, Record<string, string>]>;

    it.each(cases)('%j → %j', (code, expected) => {
      expect(htmlStyleToCSSVariables({ code })).toMatchObject(expected);
    });
  });

  describe('heading styles', () => {
    const cases = [
      [
        { h1: { fontSize: 24, bold: true } },
        {
          '--eti-h1-font-size': '24px',
          '--eti-h1-font-weight': 'bold',
        },
      ],
      [
        { h2: { fontSize: 20, bold: false } },
        {
          '--eti-h2-font-size': '20px',
          '--eti-h2-font-weight': 'normal',
        },
      ],
      [{ h3: { fontSize: 18 } }, { '--eti-h3-font-size': '18px' }],
      [{}, {}],
    ] as Array<[HtmlStyle, CSSProperties]>;

    it.each(cases)('%j → %j', (input, expected) => {
      expect(htmlStyleToCSSVariables(input)).toMatchObject(expected);
    });
  });

  it('maps blockquote styles to CSS variables', () => {
    expect(
      htmlStyleToCSSVariables({
        blockquote: {
          borderColor: '#ccc',
          borderWidth: 3,
          gapWidth: 12,
          color: '#444',
        },
      })
    ).toMatchObject({
      '--eti-blockquote-border-color': '#ccc',
      '--eti-blockquote-border-width': '3px',
      '--eti-blockquote-gap-width': '12px',
      '--eti-blockquote-color': '#444',
    });
  });

  it('maps codeblock styles to CSS variables', () => {
    expect(
      htmlStyleToCSSVariables({
        codeblock: {
          backgroundColor: '#1e1e1e',
          color: '#d4d4d4',
          borderRadius: 8,
        },
      })
    ).toMatchObject({
      '--eti-codeblock-bg-color': '#1e1e1e',
      '--eti-codeblock-color': '#d4d4d4',
      '--eti-codeblock-border-radius': '8px',
    });
  });

  it('maps anchor link styles to CSS variables', () => {
    expect(
      htmlStyleToCSSVariables({
        a: { color: 'blue', textDecorationLine: 'underline' },
      })
    ).toMatchObject({
      '--eti-link-color': 'blue',
      '--eti-link-text-decoration-line': 'underline',
    });
  });

  it('maps ul styles to CSS variables', () => {
    expect(
      htmlStyleToCSSVariables({
        ul: {
          bulletColor: '#ff0000',
          bulletSize: 12,
          marginLeft: 8,
          gapWidth: 4,
        },
      })
    ).toMatchObject({
      '--eti-ul-bullet-color': '#ff0000',
      '--eti-ul-bullet-size': '12px',
      '--eti-ul-margin-left': '8px',
      '--eti-ul-gap-width': '4px',
    });
  });

  it('maps ol styles to CSS variables', () => {
    expect(
      htmlStyleToCSSVariables({
        ol: {
          gapWidth: 6,
          marginLeft: 10,
          markerFontWeight: '700',
          markerColor: '#00ff00',
        },
      })
    ).toMatchObject({
      '--eti-ol-gap-width': '6px',
      '--eti-ol-margin-left': '10px',
      '--eti-ol-marker-font-weight': '700',
      '--eti-ol-marker-color': '#00ff00',
    });
  });

  it('maps ulCheckbox styles to CSS variables', () => {
    expect(
      htmlStyleToCSSVariables({
        ulCheckbox: {
          boxSize: 20,
          gapWidth: 8,
          marginLeft: 12,
          boxColor: '#336699',
        },
      })
    ).toMatchObject({
      '--eti-checkbox-box-size': '20px',
      '--eti-checkbox-gap-width': '8px',
      '--eti-checkbox-margin-left': '12px',
      '--eti-checkbox-box-color': '#336699',
    });
  });
});

describe('mention CSS variables', () => {
  it('flat mention → default vars', () => {
    const vars = htmlStyleToCSSVariables({
      mention: { color: '#f00' },
    }) as Record<string, string>;
    expect(vars['--eti-mention-default-color']).toBe('#f00');
  });

  it('mention @ + default vars', () => {
    const merged = mergeWithDefaultHtmlStyle({
      mention: { '@': { color: '#ff0000' } },
    });
    const vars = htmlStyleToCSSVariables(merged) as Record<string, string>;
    expect(vars['--eti-mention-u0040-color']).toBe('#ff0000');
    expect(vars['--eti-mention-default-color']).toBe(
      DEFAULT_HTML_STYLE.mention.color
    );
  });

  it('mention {} → default vars', () => {
    const vars = htmlStyleToCSSVariables({ mention: {} }) as Record<
      string,
      string
    >;
    expect(vars['--eti-mention-default-color']).toBe(
      DEFAULT_HTML_STYLE.mention.color
    );
  });
});
