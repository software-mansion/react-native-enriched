package com.swmansion.enriched.common

import com.facebook.react.bridge.ReadableMap
import com.facebook.react.uimanager.PixelUtil

internal const val ALLOW_FONT_SCALING_PROP = "allowFontScaling"

internal const val ALLOW_FONT_SCALING_DEFAULT = true

// Converts a logical font-unit value to pixels. When the editor is opted out of
// system font scaling, DP is used so the system font-size slider doesn't grow
// the value; otherwise SP is used and the value scales as usual.
internal fun pixelFromSpOrDp(
  value: Float,
  allowFontScaling: Boolean,
): Float =
  if (allowFontScaling) {
    PixelUtil.toPixelFromSP(value)
  } else {
    PixelUtil.toPixelFromDIP(value)
  }

internal fun pixelFromSpOrDp(
  value: Double,
  allowFontScaling: Boolean,
): Float =
  if (allowFontScaling) {
    PixelUtil.toPixelFromSP(value)
  } else {
    PixelUtil.toPixelFromDIP(value)
  }

// Reads allowFontScaling from a serialized prop map (used in MeasurementStore
// where no view instance is available yet).
internal fun allowFontScalingFromProps(props: ReadableMap?): Boolean {
  if (props == null) return true
  if (!props.hasKey(ALLOW_FONT_SCALING_PROP) || props.isNull(ALLOW_FONT_SCALING_PROP)) return ALLOW_FONT_SCALING_DEFAULT
  return props.getBoolean(ALLOW_FONT_SCALING_PROP)
}
