import type { CSSProperties } from 'react';
import type { ColorValue } from 'react-native';
import type { HtmlStyle } from '../../types';
import { DEFAULT_HTML_STYLE } from '../../utils/defaultHtmlStyle';
import { HEADING_TAGS } from '../formats/EnrichedHeading';
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

const ETI_CSS_VARS = {
  codeColor: '--eti-code-color',
  codeBgColor: '--eti-code-bg-color',
  blockquoteBorderColor: '--eti-blockquote-border-color',
  blockquoteBorderWidth: '--eti-blockquote-border-width',
  blockquoteGapWidth: '--eti-blockquote-gap-width',
  blockquoteColor: '--eti-blockquote-color',
  codeblockBgColor: '--eti-codeblock-bg-color',
  codeblockColor: '--eti-codeblock-color',
  codeblockBorderRadius: '--eti-codeblock-border-radius',
  ulBulletColor: '--eti-ul-bullet-color',
  ulBulletSize: '--eti-ul-bullet-size',
  ulMarginLeft: '--eti-ul-margin-left',
  ulGapWidth: '--eti-ul-gap-width',
  olMarginLeft: '--eti-ol-margin-left',
  olGapWidth: '--eti-ol-gap-width',
  olMarkerColor: '--eti-ol-marker-color',
  olMarkerFontWeight: '--eti-ol-marker-font-weight',
} as const;

function setColorVar(
  vars: Record<string, string>,
  name: string,
  value?: ColorValue
): void {
  const c = toColor(value);
  if (c) vars[name] = c;
}

function setPxVar(
  vars: Record<string, string>,
  name: string,
  n?: number | null
): void {
  if (n != null) vars[name] = `${n}px`;
}

function applyCodeVars(
  vars: Record<string, string>,
  code?: HtmlStyle['code']
): void {
  setColorVar(vars, ETI_CSS_VARS.codeColor, code?.color);
  setColorVar(vars, ETI_CSS_VARS.codeBgColor, code?.backgroundColor);
}

function applyHeadingVars(
  vars: Record<string, string>,
  htmlStyle?: HtmlStyle
): void {
  for (const level of HEADING_TAGS) {
    const h = htmlStyle?.[level];
    if (h?.fontSize != null)
      vars[`--eti-${level}-font-size`] = `${h.fontSize}px`;
    if (h?.bold != null)
      vars[`--eti-${level}-font-weight`] = h.bold ? 'bold' : 'normal';
  }
}

function applyBlockquoteVars(
  vars: Record<string, string>,
  bq?: HtmlStyle['blockquote']
): void {
  setColorVar(vars, ETI_CSS_VARS.blockquoteBorderColor, bq?.borderColor);
  setPxVar(vars, ETI_CSS_VARS.blockquoteBorderWidth, bq?.borderWidth);
  setPxVar(vars, ETI_CSS_VARS.blockquoteGapWidth, bq?.gapWidth);
  setColorVar(vars, ETI_CSS_VARS.blockquoteColor, bq?.color);
}

function applyCodeblockVars(
  vars: Record<string, string>,
  cb?: HtmlStyle['codeblock']
): void {
  setColorVar(vars, ETI_CSS_VARS.codeblockBgColor, cb?.backgroundColor);
  setColorVar(vars, ETI_CSS_VARS.codeblockColor, cb?.color);
  setPxVar(vars, ETI_CSS_VARS.codeblockBorderRadius, cb?.borderRadius);
}

function applyUnorderedListVars(
  vars: Record<string, string>,
  ul?: HtmlStyle['ul']
): void {
  setColorVar(vars, ETI_CSS_VARS.ulBulletColor, ul?.bulletColor);
  setPxVar(vars, ETI_CSS_VARS.ulBulletSize, ul?.bulletSize);
  setPxVar(vars, ETI_CSS_VARS.ulMarginLeft, ul?.marginLeft);
  setPxVar(vars, ETI_CSS_VARS.ulGapWidth, ul?.gapWidth);
}

function applyOrderedListVars(
  vars: Record<string, string>,
  ol?: HtmlStyle['ol']
): void {
  setPxVar(vars, ETI_CSS_VARS.olMarginLeft, ol?.marginLeft);
  setPxVar(vars, ETI_CSS_VARS.olGapWidth, ol?.gapWidth);
  setColorVar(vars, ETI_CSS_VARS.olMarkerColor, ol?.markerColor);
  if (ol?.markerFontWeight != null) {
    vars[ETI_CSS_VARS.olMarkerFontWeight] = String(ol.markerFontWeight);
  }
}

export function htmlStyleToCSSVariables(htmlStyle?: HtmlStyle): CSSProperties {
  const vars: Record<string, string> = {};
  applyCodeVars(vars, htmlStyle?.code);
  applyHeadingVars(vars, htmlStyle);
  applyBlockquoteVars(vars, htmlStyle?.blockquote);
  applyCodeblockVars(vars, htmlStyle?.codeblock);
  applyUnorderedListVars(vars, htmlStyle?.ul);
  applyOrderedListVars(vars, htmlStyle?.ol);
  return vars as CSSProperties;
}
