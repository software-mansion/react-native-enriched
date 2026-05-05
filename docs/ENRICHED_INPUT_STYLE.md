# EnrichedInputStyle

Defines the [`style`](API_REFERENCE.md#style) prop’s shape. This type is a subset of React Native’s [TextStyle](https://reactnative.dev/docs/text-style-props), meaning some properties are not supported by this component (e.g. `textAlign`, `textDecorationLine`, `justifyContent`). Certain properties are platform-specific and include an `@platform` directive indicating where they are supported.


```ts
export interface EnrichedInputStyle {
  // Layout / FlexStyle
  alignSelf?: TextStyle['alignSelf'];
  aspectRatio?: number | string;
  borderBottomWidth?: number;
  borderEndWidth?: number;
  borderLeftWidth?: number;
  borderRightWidth?: number;
  borderStartWidth?: number;
  borderTopWidth?: number;
  borderWidth?: number;
  bottom?: DimensionValue;
  boxSizing?: TextStyle['boxSizing'];
  display?: TextStyle['display'];
  end?: DimensionValue;
  flex?: number;
  flexBasis?: DimensionValue;
  flexGrow?: number;
  flexShrink?: number;
  height?: DimensionValue;
  inset?: DimensionValue;
  insetBlock?: DimensionValue;
  insetBlockEnd?: DimensionValue;
  insetBlockStart?: DimensionValue;
  insetInline?: DimensionValue;
  insetInlineEnd?: DimensionValue;
  insetInlineStart?: DimensionValue;
  left?: DimensionValue;
  margin?: DimensionValue;
  marginBlock?: DimensionValue;
  marginBlockEnd?: DimensionValue;
  marginBlockStart?: DimensionValue;
  marginBottom?: DimensionValue;
  marginEnd?: DimensionValue;
  marginHorizontal?: DimensionValue;
  marginInline?: DimensionValue;
  marginInlineEnd?: DimensionValue;
  marginInlineStart?: DimensionValue;
  marginLeft?: DimensionValue;
  marginRight?: DimensionValue;
  marginStart?: DimensionValue;
  marginTop?: DimensionValue;
  marginVertical?: DimensionValue;
  maxHeight?: DimensionValue;
  maxWidth?: DimensionValue;
  minHeight?: DimensionValue;
  minWidth?: DimensionValue;
  padding?: DimensionValue;
  paddingBlock?: DimensionValue;
  paddingBlockEnd?: DimensionValue;
  paddingBlockStart?: DimensionValue;
  paddingBottom?: DimensionValue;
  paddingEnd?: DimensionValue;
  paddingHorizontal?: DimensionValue;
  paddingInline?: DimensionValue;
  paddingInlineEnd?: DimensionValue;
  paddingInlineStart?: DimensionValue;
  paddingLeft?: DimensionValue;
  paddingRight?: DimensionValue;
  paddingStart?: DimensionValue;
  paddingTop?: DimensionValue;
  paddingVertical?: DimensionValue;
  position?: TextStyle['position'];
  right?: DimensionValue;
  start?: DimensionValue;
  top?: DimensionValue;
  width?: DimensionValue;
  zIndex?: number;

  // Shadows
  /** @platform ios */
  shadowColor?: ColorValue;
  /** @platform ios */
  shadowOffset?: TextStyle['shadowOffset'];
  /** @platform ios */
  shadowOpacity?: TextStyle['shadowOpacity'];
  /** @platform ios */
  shadowRadius?: number;

  // Transforms
  transform?: TextStyle['transform'];
  transformOrigin?: TextStyle['transformOrigin'];

  // View appearance
  /** @platform ios web */
  backfaceVisibility?: TextStyle['backfaceVisibility'];
  backgroundColor?: ColorValue;
  /** @platform ios web */
  borderBlockColor?: ColorValue;
  /** @platform ios web */
  borderBlockEndColor?: ColorValue;
  /** @platform ios web */
  borderBlockStartColor?: ColorValue;
  /** @platform ios web */
  borderBottomColor?: ColorValue;
  /** @platform ios web */
  borderBottomEndRadius?: TextStyle['borderBottomEndRadius'];
  /** @platform ios web */
  borderBottomLeftRadius?: TextStyle['borderBottomLeftRadius'];
  /** @platform ios web */
  borderBottomRightRadius?: TextStyle['borderBottomRightRadius'];
  /** @platform ios web */
  borderBottomStartRadius?: TextStyle['borderBottomStartRadius'];
  /** @platform ios web */
  borderColor?: ColorValue;
  /** @platform ios web */
  borderEndColor?: ColorValue;
  /** @platform ios web */
  borderEndEndRadius?: TextStyle['borderEndEndRadius'];
  /** @platform ios web */
  borderEndStartRadius?: TextStyle['borderEndStartRadius'];
  /** @platform ios web */
  borderLeftColor?: ColorValue;
  /** @platform ios web */
  borderRadius?: TextStyle['borderRadius'];
  /** @platform ios web */
  borderRightColor?: ColorValue;
  /** @platform ios web */
  borderStartColor?: ColorValue;
  /** @platform ios web */
  borderStartEndRadius?: TextStyle['borderStartEndRadius'];
  /** @platform ios web */
  borderStartStartRadius?: TextStyle['borderStartStartRadius'];
  /** @platform ios web */
  borderStyle?: TextStyle['borderStyle'];
  /** @platform ios web */
  borderTopColor?: ColorValue;
  /** @platform ios web */
  borderTopEndRadius?: TextStyle['borderTopEndRadius'];
  /** @platform ios web */
  borderTopLeftRadius?: TextStyle['borderTopLeftRadius'];
  /** @platform ios web */
  borderTopRightRadius?: TextStyle['borderTopRightRadius'];
  /** @platform ios web */
  borderTopStartRadius?: TextStyle['borderTopStartRadius'];
  boxShadow?: TextStyle['boxShadow'];
  /** @platform web */
  cursor?: TextStyle['cursor'];
  /** @platform android */
  elevation?: number;
  /** @platform android web */
  filter?: TextStyle['filter'];
  /** @platform android web */
  mixBlendMode?: TextStyle['mixBlendMode'];
  opacity?: TextStyle['opacity'];
  /** @platform ios web */
  outlineColor?: ColorValue;
  outlineOffset?: TextStyle['outlineOffset'];
  /** @platform android web */
  outlineStyle?: TextStyle['outlineStyle'];
  outlineWidth?: TextStyle['outlineWidth'];
  /** @platform ios web */
  pointerEvents?: TextStyle['pointerEvents'];

  // Typography
  color?: ColorValue;
  fontFamily?: string;
  fontSize?: number;
  fontStyle?: TextStyle['fontStyle'];
  fontWeight?: TextStyle['fontWeight'];
  lineHeight?: number;
  /** @platform web */
  letterSpacing?: number;
}
```
