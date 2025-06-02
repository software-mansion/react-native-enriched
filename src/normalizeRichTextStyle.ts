import type { RichTextStyle } from './RichTextInput';
import { type ColorValue, processColor } from 'react-native';

const defaultStyle: Required<RichTextStyle> = {
  h1: {
    fontSize: 32,
  },
  h2: {
    fontSize: 24,
  },
  h3: {
    fontSize: 20,
  },
  blockquote: {
    borderColor: 'darkgray',
    borderWidth: 4,
    gapWidth: 16,
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
  },
  ul: {
    bulletColor: 'black',
    bulletSize: 8,
    marginLeft: 16,
    gapWidth: 16,
  },
};

const assignDefaultValues = (style: RichTextStyle): RichTextStyle => {
  const merged: Record<string, any> = { ...defaultStyle };

  for (const key in style) {
    merged[key] = {
      ...defaultStyle[key as keyof RichTextStyle],
      ...style[key as keyof RichTextStyle],
    };
  }
  return merged;
};

const parseColors = (style: RichTextStyle): RichTextStyle => {
  const finalStyle: Record<string, any> = {};

  for (const [tagName, tagStyle] of Object.entries(style)) {
    const tagStyles: Record<string, any> = {};

    for (const [styleName, styleValue] of Object.entries(tagStyle)) {
      if (styleName !== 'color' && !styleName.endsWith('Color')) {
        tagStyles[styleName] = styleValue;
        continue;
      }

      tagStyles[styleName] = processColor(styleValue as ColorValue);
    }

    finalStyle[tagName] = tagStyles;
  }

  return finalStyle;
};

export const normalizeRichTextStyle = (
  style: RichTextStyle = {}
): RichTextStyle => {
  const withDefaults = assignDefaultValues(style);
  return parseColors(withDefaults);
};
