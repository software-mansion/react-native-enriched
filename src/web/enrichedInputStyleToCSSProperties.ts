import type { CSSProperties } from 'react';
import type { EnrichedInputStyle } from '../types';
import type {
  AnimatableNumericValue,
  ColorValue,
  DimensionValue,
} from 'react-native';

function toPx(
  value?: DimensionValue | AnimatableNumericValue | string
): string | undefined {
  if (value == null) return undefined;
  if (typeof value === 'number') return `${value}px`;
  if (typeof value === 'string') return value;
  return undefined;
}

function toColor(value?: ColorValue): string | undefined {
  if (typeof value === 'string') return value;
  return undefined;
}

export function enrichedInputStyleToCSSProperties(
  style: EnrichedInputStyle
): CSSProperties {
  const css: CSSProperties = {
    // Dimensions
    width: toPx(style.width),
    height: toPx(style.height),
    minWidth: toPx(style.minWidth),
    maxWidth: toPx(style.maxWidth),
    minHeight: toPx(style.minHeight),
    maxHeight: toPx(style.maxHeight),
    top: toPx(style.top),
    bottom: toPx(style.bottom),
    left: toPx(style.left),
    right: toPx(style.right),
    inset: toPx(style.inset),
    insetBlock: toPx(style.insetBlock),
    insetBlockEnd: toPx(style.insetBlockEnd),
    insetBlockStart: toPx(style.insetBlockStart),
    insetInline: toPx(style.insetInline),
    insetInlineEnd: toPx(style.insetInlineEnd ?? style.end),
    insetInlineStart: toPx(style.insetInlineStart ?? style.start),

    // Margin
    margin: toPx(style.margin),
    marginTop: toPx(style.marginTop),
    marginBottom: toPx(style.marginBottom),
    marginLeft: toPx(style.marginLeft),
    marginRight: toPx(style.marginRight),
    marginBlock: toPx(style.marginBlock),
    marginBlockEnd: toPx(style.marginBlockEnd),
    marginBlockStart: toPx(style.marginBlockStart),
    marginInline: toPx(style.marginInline),
    marginInlineEnd: toPx(style.marginInlineEnd ?? style.marginEnd),
    marginInlineStart: toPx(style.marginInlineStart ?? style.marginStart),

    // Padding
    padding: toPx(style.padding),
    paddingTop: toPx(style.paddingTop),
    paddingBottom: toPx(style.paddingBottom),
    paddingLeft: toPx(style.paddingLeft),
    paddingRight: toPx(style.paddingRight),
    paddingBlock: toPx(style.paddingBlock),
    paddingBlockEnd: toPx(style.paddingBlockEnd),
    paddingBlockStart: toPx(style.paddingBlockStart),
    paddingInline: toPx(style.paddingInline),
    paddingInlineEnd: toPx(style.paddingInlineEnd ?? style.paddingEnd),
    paddingInlineStart: toPx(style.paddingInlineStart ?? style.paddingStart),

    // RN shorthands expanded (override the direct values above if set)
    ...(style.marginHorizontal != null && {
      marginLeft: toPx(style.marginHorizontal),
      marginRight: toPx(style.marginHorizontal),
    }),
    ...(style.marginVertical != null && {
      marginTop: toPx(style.marginVertical),
      marginBottom: toPx(style.marginVertical),
    }),
    ...(style.paddingHorizontal != null && {
      paddingLeft: toPx(style.paddingHorizontal),
      paddingRight: toPx(style.paddingHorizontal),
    }),
    ...(style.paddingVertical != null && {
      paddingTop: toPx(style.paddingVertical),
      paddingBottom: toPx(style.paddingVertical),
    }),

    // Border widths
    borderInlineStartWidth: toPx(style.borderStartWidth),
    borderInlineEndWidth: toPx(style.borderEndWidth),
    borderWidth: toPx(style.borderWidth),
    borderTopWidth: toPx(style.borderTopWidth),
    borderBottomWidth: toPx(style.borderBottomWidth),
    borderLeftWidth: toPx(style.borderLeftWidth),
    borderRightWidth: toPx(style.borderRightWidth),

    // Border radius (physical)
    borderRadius: toPx(style.borderRadius),
    borderTopLeftRadius: toPx(style.borderTopLeftRadius),
    borderTopRightRadius: toPx(style.borderTopRightRadius),
    borderBottomLeftRadius: toPx(style.borderBottomLeftRadius),
    borderBottomRightRadius: toPx(style.borderBottomRightRadius),

    // Border radius (logical) — CSS name takes priority over RN name via ??
    borderStartStartRadius: toPx(
      style.borderStartStartRadius ?? style.borderTopStartRadius
    ),
    borderStartEndRadius: toPx(
      style.borderStartEndRadius ?? style.borderTopEndRadius
    ),
    borderEndStartRadius: toPx(
      style.borderEndStartRadius ?? style.borderBottomStartRadius
    ),
    borderEndEndRadius: toPx(
      style.borderEndEndRadius ?? style.borderBottomEndRadius
    ),

    // Border colors (ColorValue is always a string on web)
    borderColor: toColor(style.borderColor),
    borderBlockColor: toColor(style.borderBlockColor),
    borderBlockEndColor: toColor(style.borderBlockEndColor),
    borderBlockStartColor: toColor(style.borderBlockStartColor),
    borderBottomColor: toColor(style.borderBottomColor),
    borderInlineEndColor: toColor(style.borderEndColor),
    borderLeftColor: toColor(style.borderLeftColor),
    borderRightColor: toColor(style.borderRightColor),
    borderInlineStartColor: toColor(style.borderStartColor),
    borderTopColor: toColor(style.borderTopColor),
    borderStyle: style.borderStyle,

    // Typography
    color: toColor(style.color),
    fontFamily: style.fontFamily,
    fontSize: toPx(style.fontSize),
    fontStyle: style.fontStyle,
    fontWeight: style.fontWeight,
    lineHeight: toPx(style.lineHeight),
    letterSpacing: toPx(style.letterSpacing),

    // View appearance
    backgroundColor: toColor(style.backgroundColor),
    // boxShadow/filter: RN accepts arrays, CSS only strings
    boxShadow:
      typeof style.boxShadow === 'string' ? style.boxShadow : undefined,
    display: style.display,
    position: style.position,
    alignSelf: style.alignSelf,
    backfaceVisibility: style.backfaceVisibility,
    cursor: style.cursor,
    filter: typeof style.filter === 'string' ? style.filter : undefined,
    mixBlendMode: style.mixBlendMode,
    boxSizing: style.boxSizing,
    // pointerEvents: RN 'box-none'/'box-only' have no CSS equivalent
    pointerEvents:
      style.pointerEvents === 'auto' || style.pointerEvents === 'none'
        ? style.pointerEvents
        : undefined,

    // Outline
    outlineColor: toColor(style.outlineColor),
    outlineStyle: style.outlineStyle,
    outlineOffset: toPx(style.outlineOffset),
    outlineWidth: toPx(style.outlineWidth),

    // Transforms - RN accepts arrays, CSS only strings
    transform:
      typeof style.transform === 'string' ? style.transform : undefined,
    transformOrigin:
      typeof style.transformOrigin === 'string'
        ? style.transformOrigin
        : undefined,

    // Flex
    flex: style.flex,
    flexGrow: style.flexGrow,
    flexShrink: style.flexShrink,
    flexBasis: toPx(style.flexBasis),

    // Misc
    zIndex: style.zIndex,
    // opacity: RN AnimatableNumericValue includes AnimatedNode; CSS only number
    opacity: typeof style.opacity === 'number' ? style.opacity : undefined,
    aspectRatio: style.aspectRatio,
  };

  // Clean undefined values
  return Object.fromEntries(
    Object.entries(css).filter(([, v]) => v !== undefined)
  ) as CSSProperties;
}
