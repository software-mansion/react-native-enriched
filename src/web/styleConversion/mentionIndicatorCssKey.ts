export const MENTION_STYLE_DEFAULT_KEY = 'default';

export function indicatorToMentionCssKey(indicator: string): string {
  if (indicator === MENTION_STYLE_DEFAULT_KEY) {
    return MENTION_STYLE_DEFAULT_KEY;
  }

  const cp = indicator.codePointAt(0);
  if (cp === undefined) {
    return 'u0000';
  }
  const hex = cp.toString(16).toUpperCase();
  return 'u' + hex.padStart(Math.max(4, hex.length), '0');
}
