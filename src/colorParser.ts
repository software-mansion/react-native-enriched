import type { RichTextStyle } from './RichTextInput';
import { type ColorValue, processColor } from 'react-native';

export const parseColors = (
  style: RichTextStyle | undefined
): RichTextStyle | undefined => {
  if (!style) return undefined;

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
