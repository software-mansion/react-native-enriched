package com.swmansion.reactnativerichtexteditor.styles

import com.facebook.react.bridge.ReadableMap
import com.facebook.react.uimanager.PixelUtil
import kotlin.math.ceil

class RichTextStyle {
  var h1FontSize: Int = defaults.h1.fontSize
  var h2FontSize: Int = defaults.h2.fontSize
  var h3FontSize: Int = defaults.h3.fontSize

  constructor(style: ReadableMap?) {
    if (style == null) return

    var h1Style = style.getMap("h1")
    h1FontSize = getFontSize(h1Style, defaults.h1.fontSize)

    var h2Style = style.getMap("h2")
    h2FontSize = getFontSize(h2Style, defaults.h2.fontSize)

    var h3Style = style.getMap("h3")
    h3FontSize = getFontSize(h3Style, defaults.h3.fontSize)
  }

  fun getFontSize(map: ReadableMap?, defaultValue: Int): Int {
    if (map == null) return defaultValue

    if (!map.hasKey("fontSize")) return defaultValue

    if (map.isNull("fontSize")) return defaultValue

    val fontSize = map.getDouble("fontSize")
    return ceil(PixelUtil.toPixelFromSP(fontSize)).toInt()
  }

  companion object {
      data class HeadingStyle(val fontSize: Int)

      data class Defaults(
        val h1: HeadingStyle,
        val h2: HeadingStyle,
        val h3: HeadingStyle
      )

      val defaults = Defaults(
        h1 = HeadingStyle(72),
        h2 = HeadingStyle(64),
        h3 = HeadingStyle(56)
      )
  }
}
