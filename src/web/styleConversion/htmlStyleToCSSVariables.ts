import type { CSSProperties } from 'react';
import type { ColorValue } from 'react-native';
import type { HtmlStyle, MentionStyleProperties } from '../../types';
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
  linkColor: '--eti-link-color',
  linkTextDecorationLine: '--eti-link-text-decoration-line',
  mentionColor: '--eti-mention-color',
  mentionBgColor: '--eti-mention-bg-color',
  mentionTextDecorationLine: '--eti-mention-text-decoration-line',
  ulBulletColor: '--eti-ul-bullet-color',
  ulBulletSize: '--eti-ul-bullet-size',
  ulMarginLeft: '--eti-ul-margin-left',
  ulGapWidth: '--eti-ul-gap-width',
  olMarginLeft: '--eti-ol-margin-left',
  olGapWidth: '--eti-ol-gap-width',
  olMarkerColor: '--eti-ol-marker-color',
  olMarkerFontWeight: '--eti-ol-marker-font-weight',
  checkboxBoxSize: '--eti-checkbox-box-size',
  checkboxGapWidth: '--eti-checkbox-gap-width',
  checkboxMarginLeft: '--eti-checkbox-margin-left',
  checkboxBoxColor: '--eti-checkbox-box-color',
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

function applyLinkVars(
  vars: Record<string, string>,
  anchor?: HtmlStyle['a']
): void {
  setColorVar(vars, ETI_CSS_VARS.linkColor, anchor?.color);
  if (anchor?.textDecorationLine != null) {
    vars[ETI_CSS_VARS.linkTextDecorationLine] = anchor.textDecorationLine;
  }
}

function isByIndicatorMap(
  mention: HtmlStyle['mention']
): mention is Record<string, MentionStyleProperties> {
  if (!mention || typeof mention !== 'object' || Array.isArray(mention)) {
    return false;
  }
  // Distinguish Record<indicator, MentionStyleProperties> from MentionStyleProperties:
  // MentionStyleProperties keys are color, backgroundColor, textDecorationLine.
  const flatKeys: Array<keyof MentionStyleProperties> = [
    'color',
    'backgroundColor',
    'textDecorationLine',
  ];
  const keys = Object.keys(mention);
  return keys.some(
    (k) => !flatKeys.includes(k as keyof MentionStyleProperties)
  );
}

function mentionPropsToVarBlock(m: MentionStyleProperties): string {
  const parts: string[] = [];
  const color = toColor(m.color);
  if (color) parts.push(`  color: ${color};`);
  const bg = toColor(m.backgroundColor);
  if (bg) parts.push(`  background-color: ${bg};`);
  if (m.textDecorationLine != null) {
    parts.push(`  text-decoration-line: ${m.textDecorationLine};`);
  }
  return parts.join('\n');
}

function applyMentionVars(
  vars: Record<string, string>,
  mention?: HtmlStyle['mention']
): void {
  if (!mention) return;

  if (isByIndicatorMap(mention)) {
    // Per-indicator map — apply default/fallback vars for indicators without specific rules
    const byIndicator = mention as Record<string, MentionStyleProperties>;
    const fallback = byIndicator.default;
    const m = fallback ?? byIndicator[Object.keys(byIndicator)[0]!];
    if (m) {
      setColorVar(vars, ETI_CSS_VARS.mentionColor, m.color);
      setColorVar(vars, ETI_CSS_VARS.mentionBgColor, m.backgroundColor);
      if (m.textDecorationLine != null) {
        vars[ETI_CSS_VARS.mentionTextDecorationLine] = m.textDecorationLine;
      }
    }
  } else {
    // Flat MentionStyleProperties
    const m = mention as MentionStyleProperties;
    setColorVar(vars, ETI_CSS_VARS.mentionColor, m.color);
    setColorVar(vars, ETI_CSS_VARS.mentionBgColor, m.backgroundColor);
    if (m.textDecorationLine != null) {
      vars[ETI_CSS_VARS.mentionTextDecorationLine] = m.textDecorationLine;
    }
  }
}

/**
 * Generates per-indicator CSS rules for `<mention indicator="X">` elements.
 * Returns an empty string when the mention style is flat (single-indicator).
 */
export function mentionIndicatorCssRules(
  mention?: HtmlStyle['mention']
): string {
  if (!mention || !isByIndicatorMap(mention)) return '';

  const byIndicator = mention as Record<string, MentionStyleProperties>;
  const blocks: string[] = [];

  for (const [indicator, props] of Object.entries(byIndicator)) {
    if (indicator === 'default') continue;
    const body = mentionPropsToVarBlock(props);
    if (!body) continue;
    // Escape the indicator for use in an attribute selector value
    const escaped = indicator.replace(/\\/g, '\\\\').replace(/"/g, '\\"');
    blocks.push(`.eti-editor mention[indicator="${escaped}"] {\n${body}\n}`);
  }

  return blocks.join('\n');
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

function applyCheckboxListVars(
  vars: Record<string, string>,
  ulCheckbox?: HtmlStyle['ulCheckbox']
): void {
  setPxVar(vars, ETI_CSS_VARS.checkboxBoxSize, ulCheckbox?.boxSize);
  setPxVar(vars, ETI_CSS_VARS.checkboxGapWidth, ulCheckbox?.gapWidth);
  setPxVar(vars, ETI_CSS_VARS.checkboxMarginLeft, ulCheckbox?.marginLeft);
  setColorVar(vars, ETI_CSS_VARS.checkboxBoxColor, ulCheckbox?.boxColor);
}

export function htmlStyleToCSSVariables(htmlStyle?: HtmlStyle): CSSProperties {
  const vars: Record<string, string> = {};
  applyCodeVars(vars, htmlStyle?.code);
  applyHeadingVars(vars, htmlStyle);
  applyBlockquoteVars(vars, htmlStyle?.blockquote);
  applyCodeblockVars(vars, htmlStyle?.codeblock);
  applyLinkVars(vars, htmlStyle?.a);
  applyMentionVars(vars, htmlStyle?.mention);
  applyUnorderedListVars(vars, htmlStyle?.ul);
  applyOrderedListVars(vars, htmlStyle?.ol);
  applyCheckboxListVars(vars, htmlStyle?.ulCheckbox);
  return vars as CSSProperties;
}
