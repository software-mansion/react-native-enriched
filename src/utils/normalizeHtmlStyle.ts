import { type ColorValue, processColor } from 'react-native';
import type { HtmlStyleInternal } from '../spec/EnrichedTextInputNativeComponent';
import type {
  EnrichedTextHtmlStyle,
  HtmlStyle,
  MentionStyleProperties,
} from '../types';
import type { EnrichedTextHtmlStyleInternal } from '../spec/EnrichedTextNativeComponent';
import {
  DEFAULT_HTML_STYLE,
  DEFAULT_ENRICHED_TEXT_STYLE,
} from './defaultHtmlStyle';
import { expandMentionStylesForIndicators } from './expandMentionStylesForIndicators';

const MENTION_DEFAULT_KEY = '_default';

const parseOlStyles = (style: HtmlStyle) => {
  let markerFontWeight: string | undefined;
  if (style.ol?.markerFontWeight) {
    if (typeof style.ol?.markerFontWeight === 'number') {
      markerFontWeight = String(style.ol?.markerFontWeight);
    } else if (typeof style.ol?.markerFontWeight === 'string') {
      markerFontWeight = style.ol?.markerFontWeight;
    }
  }

  return {
    ...style.ol,
    markerFontWeight: markerFontWeight,
  };
};

const convertToHtmlStyleInternal = (
  style: HtmlStyle,
  mentionIndicators: string[]
): HtmlStyleInternal => {
  const mentionStyles = expandMentionStylesForIndicators(
    style.mention,
    mentionIndicators
  );

  let markerFontWeight: string | undefined;
  if (style.ol?.markerFontWeight) {
    if (typeof style.ol?.markerFontWeight === 'number') {
      markerFontWeight = String(style.ol?.markerFontWeight);
    } else if (typeof style.ol?.markerFontWeight === 'string') {
      markerFontWeight = style.ol?.markerFontWeight;
    }
  }

  const olStyles = {
    ...style.ol,
    markerFontWeight: markerFontWeight,
  };

  return {
    ...style,
    mention: mentionStyles,
    ol: olStyles,
  };
};

const convertToEnrichedTextHtmlStyleInternal = (
  style: EnrichedTextHtmlStyle
): EnrichedTextHtmlStyleInternal => {
  const mentionStyles: Record<string, MentionStyleProperties> = {};

  const mention = style.mention;
  if (mention && typeof mention === 'object' && !Array.isArray(mention)) {
    for (const key of Object.keys(mention)) {
      const value = (mention as Record<string, unknown>)[key];

      if (typeof value === 'object' && value !== null) {
        mentionStyles[key] = {
          ...DEFAULT_ENRICHED_TEXT_STYLE.mention,
          ...(value as MentionStyleProperties),
        };
      } else {
        mentionStyles[MENTION_DEFAULT_KEY] = {
          ...DEFAULT_ENRICHED_TEXT_STYLE.mention,
          ...(mention as MentionStyleProperties),
        };
      }
    }
  }

  if (mentionStyles[MENTION_DEFAULT_KEY] === undefined) {
    mentionStyles[MENTION_DEFAULT_KEY] = {
      ...DEFAULT_ENRICHED_TEXT_STYLE.mention,
    };
  }

  return {
    ...style,
    mention: mentionStyles,
    ol: parseOlStyles(style),
  };
};

const assignDefaultValues = <T extends Record<string, any>>(
  style: T,
  base: Record<string, any>
): HtmlStyleInternal => {
  const merged: Record<string, any> = { ...base };

  for (const key in style) {
    if (key === 'mention') {
      merged[key] = {
        ...(style.mention as object),
      };

      continue;
    }

    merged[key] = {
      ...(base[key] ?? {}),
      ...(style[key as keyof typeof style] as object),
    };
  }

  return merged as HtmlStyleInternal;
};

const parseStyle = (name: string, value: unknown) => {
  if (name !== 'color' && !name.endsWith('Color')) {
    return value;
  }

  return processColor(value as ColorValue);
};

const parseColors = (style: HtmlStyleInternal): HtmlStyleInternal => {
  const finalStyle: Record<string, any> = {};

  for (const [tagName, tagStyle] of Object.entries(style)) {
    const tagStyles: Record<string, any> = {};

    if (tagName === 'mention') {
      for (const [indicator, mentionStyle] of Object.entries(tagStyle)) {
        tagStyles[indicator] = {};

        for (const [styleName, styleValue] of Object.entries(
          mentionStyle as MentionStyleProperties
        )) {
          tagStyles[indicator][styleName] = parseStyle(styleName, styleValue);
        }
      }

      finalStyle[tagName] = tagStyles;
      continue;
    }

    for (const [styleName, styleValue] of Object.entries(tagStyle)) {
      tagStyles[styleName] = parseStyle(styleName, styleValue);
    }

    finalStyle[tagName] = tagStyles;
  }

  return finalStyle;
};

export const normalizeHtmlStyle = (
  style: HtmlStyle,
  mentionIndicators: string[]
): HtmlStyleInternal => {
  const converted = convertToHtmlStyleInternal(style, mentionIndicators);
  const withDefaults = assignDefaultValues(converted, DEFAULT_HTML_STYLE);
  return parseColors(withDefaults);
};

export const normalizeEnrichedTextHtmlStyle = (
  style: EnrichedTextHtmlStyle
): EnrichedTextHtmlStyleInternal => {
  const converted = convertToEnrichedTextHtmlStyleInternal(style);
  const withDefaults = assignDefaultValues(
    converted,
    DEFAULT_ENRICHED_TEXT_STYLE
  );
  return parseColors(withDefaults);
};
