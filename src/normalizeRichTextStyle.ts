import type { RichTextStyle } from './RichTextInput';
import { type ColorValue, processColor } from 'react-native';
import type {
  MentionStyleProperties,
  RichTextStyleInternal,
} from './ReactNativeRichTextEditorViewNativeComponent';

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

const isMentionStyleRecord = (
  mentionStyle: RichTextStyle['mention']
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

const assignMentionStyles = (
  style: RichTextStyle,
  mentionIndicators: string[]
): RichTextStyleInternal => {
  const mentionStyles: Record<string, MentionStyleProperties> = {};

  mentionIndicators.forEach((indicator) => {
    mentionStyles[indicator] = {
      ...defaultStyle.mention,
      ...(isMentionStyleRecord(style.mention)
        ? (style.mention[indicator] ?? style.mention.default ?? {})
        : style.mention),
    };
  });

  return {
    ...style,
    mention: mentionStyles,
  };
};

const assignDefaultValues = (
  style: RichTextStyleInternal
): RichTextStyleInternal => {
  const merged: Record<string, any> = { ...defaultStyle };

  for (const key in style) {
    if (key === 'mention') {
      merged[key] = {
        ...style.mention,
      };

      continue;
    }

    merged[key] = {
      ...defaultStyle[key as keyof RichTextStyle],
      ...style[key as keyof RichTextStyle],
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

const parseColors = (style: RichTextStyleInternal): RichTextStyleInternal => {
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

export const normalizeRichTextStyle = (
  style: RichTextStyle,
  mentionIndicators: string[]
): RichTextStyleInternal => {
  const withMentions = assignMentionStyles(style, mentionIndicators);
  const withDefaults = assignDefaultValues(withMentions);
  return parseColors(withDefaults);
};
