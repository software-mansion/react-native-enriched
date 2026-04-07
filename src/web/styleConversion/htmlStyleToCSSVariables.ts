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

export function htmlStyleWithDefaultsToCSSVariables(
  htmlStyle?: HtmlStyle
): CSSProperties {
  return htmlStyleToCSSVariables(mergeWithDefaultHtmlStyle(htmlStyle));
}

export function htmlStyleToCSSVariables(htmlStyle?: HtmlStyle): CSSProperties {
  const vars: Record<string, string> = {};

  const codeColor = toColor(htmlStyle?.code?.color);
  if (codeColor) vars['--eti-code-color'] = codeColor;

  const codeBackgroundColor = toColor(htmlStyle?.code?.backgroundColor);
  if (codeBackgroundColor) vars['--eti-code-bg-color'] = codeBackgroundColor;

  return vars as CSSProperties;
}
