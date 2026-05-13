import { mergeWithDefaultHtmlStyle } from '../htmlStyleToCSSVariables';
import { buildMentionRulesCSS } from '../buildMentionRulesCSS';

describe('buildMentionRulesCSS', () => {
  it('emits default class rule and attribute rule for @', () => {
    const merged = mergeWithDefaultHtmlStyle({
      mention: { '@': { color: 'red' } },
    });
    const css = buildMentionRulesCSS(merged);

    expect(css).toMatch(/\.eti-editor mention\s*\{/);
    expect(css).toContain('var(--eti-mention-default-color)');
    expect(css).toContain('var(--eti-mention-default-background-color)');
    expect(css).toContain('var(--eti-mention-default-text-decoration-line)');

    expect(css).toContain('.eti-editor mention[indicator="@"]');
    expect(css).toContain('var(--eti-mention-u0040-color)');
    expect(css).toContain('var(--eti-mention-u0040-background-color)');
    expect(css).toContain('var(--eti-mention-u0040-text-decoration-line)');
  });

  it('returns empty string when mention is missing', () => {
    expect(buildMentionRulesCSS(undefined)).toBe('');
    expect(buildMentionRulesCSS({})).toBe('');
  });

  it('returns empty string when mention is not a style record', () => {
    expect(buildMentionRulesCSS({ mention: { color: 'red' } })).toBe('');
  });
});
