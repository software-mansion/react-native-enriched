import type { CSSProperties } from 'react';
import type { HtmlStyle, MentionStyleProperties } from '../../../types';
import {
  DEFAULT_ENRICHED_TEXT_STYLE,
  DEFAULT_HTML_STYLE,
} from '../../../utils/defaultHtmlStyle';
import {
  enrichedTextHtmlStyleToCSSVariables,
  htmlStyleToCSSVariables,
  mergeWithDefaultHtmlStyle,
} from '../htmlStyleToCSSVariables';

type CodeStyle = HtmlStyle['code'];

const defaultMentionOnlyResolved = {
  default: { ...DEFAULT_HTML_STYLE.mention },
};

const DEFAULT_MENTION_PRESS = DEFAULT_ENRICHED_TEXT_STYLE.mention as {
  pressColor?: string;
  pressBackgroundColor?: string;
};
const DEFAULT_MENTION_PRESS_COLOR = DEFAULT_MENTION_PRESS.pressColor;
const DEFAULT_MENTION_PRESS_BACKGROUND_COLOR =
  DEFAULT_MENTION_PRESS.pressBackgroundColor;

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
  it('empty style → empty vars', () => {
    expect(htmlStyleToCSSVariables({})).toEqual({} as CSSProperties);
  });

  it('integer color → rgba string', () => {
    const input = { code: { color: 0xff0000ff as unknown as string } };
    expect(htmlStyleToCSSVariables(input)).toMatchObject({
      '--et-code-color': 'rgba(255, 0, 0, 1)',
    });
  });

  describe('code styles', () => {
    const cases = [
      [{ color: '#ff0000' }, { '--et-code-color': '#ff0000' }],
      [
        { color: 'rgba(0,128,255,1)' },
        { '--et-code-color': 'rgba(0,128,255,1)' },
      ],
      [{ backgroundColor: '#f5f5f5' }, { '--et-code-bg-color': '#f5f5f5' }],
      [
        { color: '#333', backgroundColor: '#f5f5f5' },
        { '--et-code-color': '#333', '--et-code-bg-color': '#f5f5f5' },
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
          '--et-h1-font-size': '24px',
          '--et-h1-font-weight': 'bold',
        },
      ],
      [
        { h2: { fontSize: 20, bold: false } },
        {
          '--et-h2-font-size': '20px',
          '--et-h2-font-weight': 'normal',
        },
      ],
      [{ h3: { fontSize: 18 } }, { '--et-h3-font-size': '18px' }],
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
      '--et-blockquote-border-color': '#ccc',
      '--et-blockquote-border-width': '3px',
      '--et-blockquote-gap-width': '12px',
      '--et-blockquote-color': '#444',
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
      '--et-codeblock-bg-color': '#1e1e1e',
      '--et-codeblock-color': '#d4d4d4',
      '--et-codeblock-border-radius': '8px',
    });
  });

  it('maps anchor link styles to CSS variables', () => {
    expect(
      htmlStyleToCSSVariables({
        a: {
          color: 'blue',
          textDecorationLine: 'underline',
          pressColor: 'red',
        },
      })
    ).toMatchObject({
      '--et-link-color': 'blue',
      '--et-link-text-decoration-line': 'underline',
      '--et-link-press-color': 'red',
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
      '--et-ul-bullet-color': '#ff0000',
      '--et-ul-bullet-size': '12px',
      '--et-ul-margin-left': '8px',
      '--et-ul-gap-width': '4px',
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
      '--et-ol-gap-width': '6px',
      '--et-ol-margin-left': '10px',
      '--et-ol-marker-font-weight': '700',
      '--et-ol-marker-color': '#00ff00',
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
      '--et-checkbox-box-size': '20px',
      '--et-checkbox-gap-width': '8px',
      '--et-checkbox-margin-left': '12px',
      '--et-checkbox-box-color': '#336699',
    });
  });
});

describe('mention CSS variables', () => {
  it('flat mention → default vars', () => {
    const merged = mergeWithDefaultHtmlStyle({
      mention: { color: '#f00' },
    });
    const vars = htmlStyleToCSSVariables(merged) as Record<string, string>;
    expect(vars['--et-mention-default-color']).toBe('#f00');
  });

  it('mention @ + default vars', () => {
    const merged = mergeWithDefaultHtmlStyle({
      mention: { '@': { color: '#ff0000' } },
    });
    const vars = htmlStyleToCSSVariables(merged) as Record<string, string>;
    expect(vars['--et-mention-u0040-color']).toBe('#ff0000');
    expect(vars['--et-mention-default-color']).toBe(
      DEFAULT_HTML_STYLE.mention.color
    );
  });

  it('mention {} → default vars', () => {
    const merged = mergeWithDefaultHtmlStyle({ mention: {} });
    const vars = htmlStyleToCSSVariables(merged) as Record<string, string>;
    expect(vars['--et-mention-default-color']).toBe(
      DEFAULT_HTML_STYLE.mention.color
    );
  });
});

describe('enrichedTextHtmlStyleToCSSVariables', () => {
  it('keeps the base CSS variables', () => {
    expect(
      enrichedTextHtmlStyleToCSSVariables({
        a: { color: 'blue' },
        code: { color: 'purple' },
      })
    ).toMatchObject({
      '--et-link-color': 'blue',
      '--et-code-color': 'purple',
    });
  });

  it('adds the link press color variable', () => {
    const vars = enrichedTextHtmlStyleToCSSVariables({
      a: { color: 'blue', pressColor: 'darkblue' },
    }) as Record<string, string>;
    expect(vars['--et-link-press-color']).toBe('darkblue');
  });

  it('adds two press variables for a flat mention (default key)', () => {
    const vars = enrichedTextHtmlStyleToCSSVariables({
      mention: { pressColor: '#123', pressBackgroundColor: '#456' },
    }) as Record<string, string>;
    expect(vars['--et-mention-default-press-color']).toBe('#123');
    expect(vars['--et-mention-default-press-background-color']).toBe('#456');
  });

  it('adds two press variables per mention record entry', () => {
    const vars = enrichedTextHtmlStyleToCSSVariables({
      mention: {
        '@': {
          color: '#f00',
          pressColor: '#a00',
          pressBackgroundColor: '#fee',
        },
        '#': { pressColor: '#0a0' },
      },
    }) as Record<string, string>;
    expect(vars['--et-mention-u0040-color']).toBe('#f00');
    expect(vars['--et-mention-u0040-press-color']).toBe('#a00');
    expect(vars['--et-mention-u0040-press-background-color']).toBe('#fee');
    expect(vars['--et-mention-u0023-press-color']).toBe('#0a0');
    expect(vars['--et-mention-u0023-press-background-color']).toBe(
      DEFAULT_MENTION_PRESS_BACKGROUND_COLOR
    );
  });

  it('falls back to the global defaults when press values are absent', () => {
    const vars = enrichedTextHtmlStyleToCSSVariables({
      a: { color: 'blue' },
      mention: { color: '#f00' },
    }) as Record<string, string>;
    expect(vars['--et-mention-default-press-color']).toBe(
      DEFAULT_MENTION_PRESS_COLOR
    );
    expect(vars['--et-mention-default-press-background-color']).toBe(
      DEFAULT_MENTION_PRESS_BACKGROUND_COLOR
    );
  });

  it('emits the global defaults even with no htmlStyle', () => {
    const vars = enrichedTextHtmlStyleToCSSVariables({}) as Record<
      string,
      string
    >;
    expect(vars['--et-mention-default-press-color']).toBe(
      DEFAULT_MENTION_PRESS_COLOR
    );
    expect(vars['--et-mention-default-press-background-color']).toBe(
      DEFAULT_MENTION_PRESS_BACKGROUND_COLOR
    );
  });

  it('falls back from a record indicator to the provided default indicator', () => {
    const vars = enrichedTextHtmlStyleToCSSVariables({
      mention: {
        'default': { pressColor: '#0d0', pressBackgroundColor: '#eee' },
        '@': { color: '#f00' },
      },
    }) as Record<string, string>;
    expect(vars['--et-mention-u0040-press-color']).toBe('#0d0');
    expect(vars['--et-mention-u0040-press-background-color']).toBe('#eee');
    expect(vars['--et-mention-default-press-color']).toBe('#0d0');
    expect(vars['--et-mention-default-press-background-color']).toBe('#eee');
  });

  it('mixes default-indicator and global-constant fallbacks', () => {
    const vars = enrichedTextHtmlStyleToCSSVariables({
      mention: {
        'default': { pressColor: '#0d0' },
        '@': { color: '#f00' },
      },
    }) as Record<string, string>;
    expect(vars['--et-mention-u0040-press-color']).toBe('#0d0');
    expect(vars['--et-mention-u0040-press-background-color']).toBe(
      DEFAULT_MENTION_PRESS_BACKGROUND_COLOR
    );
    expect(vars['--et-mention-default-press-color']).toBe('#0d0');
    expect(vars['--et-mention-default-press-background-color']).toBe(
      DEFAULT_MENTION_PRESS_BACKGROUND_COLOR
    );
  });
});
