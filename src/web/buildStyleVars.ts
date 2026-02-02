import type { CSSProperties } from 'react';

export interface MentionStyleProperties {
  color?: string;
  backgroundColor?: string;
  textDecorationLine?: 'underline' | 'none';
}

export type HeadingStyle = {
  fontSize?: number;
  bold?: boolean;
};

export interface HtmlStyle {
  h1?: HeadingStyle;
  h2?: HeadingStyle;
  h3?: HeadingStyle;
  h4?: HeadingStyle;
  h5?: HeadingStyle;
  h6?: HeadingStyle;
  blockquote?: {
    borderColor?: string;
    borderWidth?: number;
    gapWidth?: number;
    color?: string;
  };
  codeblock?: {
    color?: string;
    borderRadius?: number;
    backgroundColor?: string;
  };
  code?: {
    color?: string;
    backgroundColor?: string;
  };
  a?: {
    color?: string;
    textDecorationLine?: 'underline' | 'none';
  };
  mention?: Record<string, MentionStyleProperties> | MentionStyleProperties;
  ol?: {
    gapWidth?: number;
    marginLeft?: number;
    markerFontWeight?: string | number;
    markerColor?: string;
  };
  ul?: {
    bulletColor?: string;
    bulletSize?: number;
    marginLeft?: number;
    gapWidth?: number;
  };
  ulCheckbox?: {
    gapWidth?: number;
    boxSize?: number;
    marginLeft?: number;
    boxColor?: string;
  };
}

type HeadingKey = 'h1' | 'h2' | 'h3' | 'h4' | 'h5' | 'h6';
const HEADING_KEYS: HeadingKey[] = ['h1', 'h2', 'h3', 'h4', 'h5', 'h6'];

const DEFAULT_HEADING_STYLES = {
  h1: { fontSize: 32 },
  h2: { fontSize: 24 },
  h3: { fontSize: 20 },
  h4: { fontSize: 16 },
  h5: { fontSize: 14 },
  h6: { fontSize: 12 },
} as const;

const DEFAULT_BLOCKQUOTE_STYLE = {
  borderColor: 'darkgray',
  borderWidth: 4,
  gapWidth: 16,
} as const;

const DEFAULT_CODE_STYLE = {
  backgroundColor: 'darkgray',
  color: 'red',
} as const;

export const buildStyleVars = (
  htmlStyle: HtmlStyle | undefined,
  placeholderTextColor: string | undefined,
  selectionColor: string | undefined,
  cursorColor: string | undefined
) => {
  const vars: Record<string, string | undefined> = {
    '--placeholder-color': placeholderTextColor,
    '--selection-color': selectionColor,
    '--cursor-color': cursorColor,
    '--code-bg-color':
      htmlStyle?.code?.backgroundColor ?? DEFAULT_CODE_STYLE.backgroundColor,
    '--code-color': htmlStyle?.code?.color ?? DEFAULT_CODE_STYLE.color,
    '--blockquote-border-color':
      htmlStyle?.blockquote?.borderColor ??
      DEFAULT_BLOCKQUOTE_STYLE.borderColor,
    '--blockquote-border-width': `${
      htmlStyle?.blockquote?.borderWidth ?? DEFAULT_BLOCKQUOTE_STYLE.borderWidth
    }px`,
    '--blockquote-gap-width': `${
      htmlStyle?.blockquote?.gapWidth ?? DEFAULT_BLOCKQUOTE_STYLE.gapWidth
    }px`,
    '--blockquote-color': htmlStyle?.blockquote?.color,
  };

  HEADING_KEYS.forEach((key) => {
    const style = htmlStyle?.[key];
    const defaultSize = DEFAULT_HEADING_STYLES[key].fontSize;
    vars[`--${key}-font-size`] = style?.fontSize
      ? `${style.fontSize}px`
      : `${defaultSize}px`;
    vars[`--${key}-font-weight`] = style?.bold ? 'bold' : 'normal';
  });

  return vars as CSSProperties;
};
