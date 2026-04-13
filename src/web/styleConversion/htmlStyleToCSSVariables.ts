import type { CSSProperties } from 'react';
import type { HtmlStyle } from '../../types';
import { DEFAULT_HTML_STYLE } from '../../utils/defaultHtmlStyle';
import { toColor } from './toColor';

export function mergeWithDefaultHtmlStyle(
  htmlStyle?: HtmlStyle
): Required<HtmlStyle> {
  const merged: Record<string, any> = { ...DEFAULT_HTML_STYLE };

  for (const key in htmlStyle) {
    merged[key] = {
      ...DEFAULT_HTML_STYLE[key as keyof HtmlStyle],
      ...(htmlStyle[key as keyof HtmlStyle] as object),
    };
  }

  return merged as Required<HtmlStyle>;
}

export function htmlStyleToCSSVariables(htmlStyle?: HtmlStyle): CSSProperties {
  const vars: Record<string, string> = {};

  const codeColor = toColor(htmlStyle?.code?.color);
  if (codeColor) vars['--eti-code-color'] = codeColor;

  const codeBackgroundColor = toColor(htmlStyle?.code?.backgroundColor);
  if (codeBackgroundColor) vars['--eti-code-bg-color'] = codeBackgroundColor;

  const headingLevels = ['h1', 'h2', 'h3', 'h4', 'h5', 'h6'] as const;
  for (const level of headingLevels) {
    const h = htmlStyle?.[level];
    if (h?.fontSize != null)
      vars[`--eti-${level}-font-size`] = `${h.fontSize}px`;
    if (h?.bold != null)
      vars[`--eti-${level}-font-weight`] = h.bold ? 'bold' : 'normal';
  }

  const bq = htmlStyle?.blockquote;
  const bqBorderColor = toColor(bq?.borderColor);
  if (bqBorderColor) vars['--eti-blockquote-border-color'] = bqBorderColor;
  if (bq?.borderWidth != null)
    vars['--eti-blockquote-border-width'] = `${bq.borderWidth}px`;
  if (bq?.gapWidth != null)
    vars['--eti-blockquote-gap-width'] = `${bq.gapWidth}px`;
  const bqColor = toColor(bq?.color);
  if (bqColor) vars['--eti-blockquote-color'] = bqColor;

  const cb = htmlStyle?.codeblock;
  const cbBgColor = toColor(cb?.backgroundColor);
  if (cbBgColor) vars['--eti-codeblock-bg-color'] = cbBgColor;
  const cbColor = toColor(cb?.color);
  if (cbColor) vars['--eti-codeblock-color'] = cbColor;
  if (cb?.borderRadius != null)
    vars['--eti-codeblock-border-radius'] = `${cb.borderRadius}px`;

  return vars as CSSProperties;
}
