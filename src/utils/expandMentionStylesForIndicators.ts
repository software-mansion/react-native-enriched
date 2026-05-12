import type { HtmlStyle, MentionStyleProperties } from '../types';
import { DEFAULT_HTML_STYLE } from './defaultHtmlStyle';
import { isMentionStyleRecord } from './isMentionStyleRecord';

export function expandMentionStylesForIndicators(
  mention: HtmlStyle['mention'] | undefined,
  indicators: string[]
): Record<string, MentionStyleProperties> {
  const out: Record<string, MentionStyleProperties> = {};
  for (const indicator of indicators) {
    out[indicator] = {
      ...DEFAULT_HTML_STYLE.mention,
      ...(isMentionStyleRecord(mention)
        ? (mention[indicator] ?? mention.default ?? {})
        : mention),
    };
  }
  return out;
}
