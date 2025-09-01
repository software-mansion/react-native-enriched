import type { HtmlStyle } from './EnrichedTextInput';
import { type ColorValue, processColor } from 'react-native';
import type {
  MentionStyleProperties,
  HtmlStyleInternal,
} from './EnrichedTextInputNativeComponent';

const defaultStyle: Required<HtmlStyle> = {
  h1: {
    fontSize: 32,
    bold: false,
  },
  h2: {
    fontSize: 24,
    bold: false,
  },
  h3: {
    fontSize: 20,
    bold: false,
  },
  blockquote: {
    borderColor: 'darkgray',
    borderWidth: 4,
    gapWidth: 16,
    color: undefined,
  },
  codeblock: {
    color: 'black',
    borderRadius: 8,
    backgroundColor: 'darkgray',
  },
  code: {
    color: 'red',
    backgroundColor: 'darkgray',
  },
  a: {
    color: 'blue',
    textDecorationLine: 'underline',
  },
  mention: {
    color: 'blue',
    backgroundColor: 'yellow',
    textDecorationLine: 'underline',
  },
  img: {
    width: 80,
    height: 80,
  },
  ol: {
    gapWidth: 16,
    marginLeft: 16,
    markerFontWeight: undefined,
    markerColor: undefined,
  },
  ul: {
    bulletColor: 'black',
    bulletSize: 8,
    marginLeft: 16,
    gapWidth: 16,
  },
};

const isMentionStyleRecord = (
  mentionStyle: HtmlStyle['mention']
): mentionStyle is Record<string, MentionStyleProperties> => {
  if (
    mentionStyle &&
    typeof mentionStyle === 'object' &&
    !Array.isArray(mentionStyle)
  ) {
    const keys = Object.keys(mentionStyle);

    return (
      keys.length > 0 &&
      keys.every(
        (key) =>
          typeof (mentionStyle as Record<string, unknown>)[key] === 'object' &&
          (mentionStyle as Record<string, unknown>)[key] !== null
      )
    );
  }
  return false;
};

const convertToHtmlStyleInternal = (
  style: HtmlStyle,
  mentionIndicators: string[]
): HtmlStyleInternal => {
  const mentionStyles: Record<string, MentionStyleProperties> = {};

  mentionIndicators.forEach((indicator) => {
    mentionStyles[indicator] = {
      ...defaultStyle.mention,
      ...(isMentionStyleRecord(style.mention)
        ? (style.mention[indicator] ?? style.mention.default ?? {})
        : style.mention),
    };
  });

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

const assignDefaultValues = (style: HtmlStyleInternal): HtmlStyleInternal => {
  const merged: Record<string, any> = { ...defaultStyle };

  for (const key in style) {
    if (key === 'mention') {
      merged[key] = {
        ...(style.mention as object),
      };

      continue;
    }

    merged[key] = {
      ...defaultStyle[key as keyof HtmlStyle],
      ...(style[key as keyof HtmlStyle] as object),
    };
  }

  return merged;
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
  const withDefaults = assignDefaultValues(converted);
  return parseColors(withDefaults);
};
