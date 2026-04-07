import type { CSSProperties } from 'react';
import type { HtmlStyle } from '../../types';
import { toColor } from './toColor';

export function htmlStyleToCSSVariables(htmlStyle?: HtmlStyle): CSSProperties {
  const vars: Record<string, string> = {};

  const codeColor = toColor(htmlStyle?.code?.color);
  if (codeColor) vars['--eti-code-color'] = codeColor;

  const codeBackgroundColor = toColor(htmlStyle?.code?.backgroundColor);
  if (codeBackgroundColor) vars['--eti-code-bg-color'] = codeBackgroundColor;

  return vars as CSSProperties;
}
