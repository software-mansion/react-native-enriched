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

function resolveTransform(
  transform: EnrichedInputStyle['transform']
): string | undefined {
  if (typeof transform === 'string') return transform;
  if (!Array.isArray(transform)) return undefined;

  const parts = transform.map((item) => {
    if ('translateX' in item) return `translateX(${item.translateX}px)`;
    if ('translateY' in item) return `translateY(${item.translateY}px)`;
    if ('translateZ' in item) return `translateZ(${item.translateZ}px)`;
    if ('scale' in item) return `scale(${item.scale})`;
    if ('scaleX' in item) return `scaleX(${item.scaleX})`;
    if ('scaleY' in item) return `scaleY(${item.scaleY})`;
    if ('scaleZ' in item) return `scaleZ(${item.scaleZ})`;
    if ('rotate' in item) return `rotate(${item.rotate})`;
    if ('rotateX' in item) return `rotateX(${item.rotateX})`;
    if ('rotateY' in item) return `rotateY(${item.rotateY})`;
    if ('rotateZ' in item) return `rotateZ(${item.rotateZ})`;
    if ('skewX' in item) return `skewX(${item.skewX})`;
    if ('skewY' in item) return `skewY(${item.skewY})`;
    if ('perspective' in item) return `perspective(${item.perspective}px)`;
    if ('matrix' in item) {
      return item.matrix.length === 16
        ? `matrix3d(${item.matrix.join(', ')})`
        : `matrix(${item.matrix.join(', ')})`;
    }
    return null;
  });

  const css = parts.filter(Boolean).join(' ');
  return css || undefined;
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

    // Margin — specific properties take precedence over shorthands (RN behavior)
    margin: toPx(style.margin),
    marginTop: toPx(style.marginTop ?? style.marginVertical),
    marginBottom: toPx(style.marginBottom ?? style.marginVertical),
    marginLeft: toPx(style.marginLeft ?? style.marginHorizontal),
    marginRight: toPx(style.marginRight ?? style.marginHorizontal),
    marginBlock: toPx(style.marginBlock),
    marginBlockEnd: toPx(style.marginBlockEnd),
    marginBlockStart: toPx(style.marginBlockStart),
    marginInline: toPx(style.marginInline),
    marginInlineEnd: toPx(style.marginInlineEnd ?? style.marginEnd),
    marginInlineStart: toPx(style.marginInlineStart ?? style.marginStart),

    // Padding — specific properties take precedence over shorthands (RN behavior)
    padding: toPx(style.padding),
    paddingTop: toPx(style.paddingTop ?? style.paddingVertical),
    paddingBottom: toPx(style.paddingBottom ?? style.paddingVertical),
    paddingLeft: toPx(style.paddingLeft ?? style.paddingHorizontal),
    paddingRight: toPx(style.paddingRight ?? style.paddingHorizontal),
    paddingBlock: toPx(style.paddingBlock),
    paddingBlockEnd: toPx(style.paddingBlockEnd),
    paddingBlockStart: toPx(style.paddingBlockStart),
    paddingInline: toPx(style.paddingInline),
    paddingInlineEnd: toPx(style.paddingInlineEnd ?? style.paddingEnd),
    paddingInlineStart: toPx(style.paddingInlineStart ?? style.paddingStart),

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

    // Border radius (logical)
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

    // Border colors
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
    borderStyle:
      style.borderStyle ??
      (style.borderWidth != null ||
      style.borderTopWidth != null ||
      style.borderBottomWidth != null ||
      style.borderLeftWidth != null ||
      style.borderRightWidth != null ||
      style.borderStartWidth != null ||
      style.borderEndWidth != null ||
      style.borderColor != null
        ? 'solid'
        : undefined),

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
    outlineStyle:
      style.outlineStyle ?? (style.outlineWidth != null ? 'solid' : undefined),
    outlineOffset: toPx(style.outlineOffset),
    outlineWidth: toPx(style.outlineWidth),

    // Transforms — array form (RN syntax) is not supported on web
    transform: resolveTransform(style.transform),
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
  );
}
