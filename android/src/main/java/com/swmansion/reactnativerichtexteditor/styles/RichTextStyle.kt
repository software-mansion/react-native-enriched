package com.swmansion.reactnativerichtexteditor.styles

import android.graphics.Color
import com.facebook.react.bridge.ColorPropConverter
import com.facebook.react.bridge.ReactContext
import com.facebook.react.bridge.ReadableMap
import com.facebook.react.uimanager.PixelUtil
import kotlin.Float
import kotlin.Int
import kotlin.String
import kotlin.math.ceil

class RichTextStyle {
  private var context: ReactContext? = null

  var h1FontSize: Int
  var h2FontSize: Int
  var h3FontSize: Int

  var blockquoteColor: Int
  var blockquoteStripeWidth: Int
  var blockquoteGapWidth: Int

  var olGapWidth: Int

  var ulGapWidth: Int
  var ulMarginLeft: Int
  var ulBulletSize: Int
  var ulBulletColor: Int

  var imgWidth: Int
  var imgHeight: Int

  var aColor: Int
  var aUnderline: Boolean

  var codeBlockColor: Int
  var codeBlockBackgroundColor: Int
  var codeBlockRadius: Float

  var inlineCodeColor: Int
  var inlineCodeBackgroundColor: Int

  var mentionColor: Int
  var mentionBackgroundColor: Int
  var mentionUnderline: Boolean

  constructor(context: ReactContext, style: ReadableMap?) {
    this.context = context

    // Default values are ignored as they are specified on the JS side.
    // They are specified only because they are required by the constructor.
    // JS passes them as a prop - so they are initialized after the constructor is called.
    if (style == null) {
      h1FontSize = 72
      h2FontSize = 64
      h3FontSize = 56
      blockquoteColor = Color.BLACK
      blockquoteStripeWidth = 2
      blockquoteGapWidth = 16
      olGapWidth = 16
      ulGapWidth = 16
      ulMarginLeft = 16
      ulBulletSize = 8
      ulBulletColor = Color.BLACK
      imgWidth = 200
      imgHeight = 200
      aColor = Color.BLACK
      aUnderline = true
      codeBlockColor = Color.BLACK
      codeBlockBackgroundColor = Color.BLACK
      codeBlockRadius = 4f
      inlineCodeColor = Color.BLACK
      inlineCodeBackgroundColor = Color.BLACK
      mentionColor = 0xFF0000FF.toInt() // Default blue
      mentionBackgroundColor = Color.BLACK
      mentionUnderline = true

      return
    }

    val h1Style = style.getMap("h1")
    h1FontSize = parseFloat(h1Style, "fontSize").toInt()

    val h2Style = style.getMap("h2")
    h2FontSize = parseFloat(h2Style, "fontSize").toInt()

    val h3Style = style.getMap("h3")
    h3FontSize = parseFloat(h3Style, "fontSize").toInt()

    val blockquoteStyle = style.getMap("blockquote")
    blockquoteColor = parseColor(blockquoteStyle, "borderColor")
    blockquoteGapWidth = parseFloat(blockquoteStyle, "gapWidth").toInt()
    blockquoteStripeWidth = parseFloat(blockquoteStyle, "borderWidth").toInt()

    val olStyle = style.getMap("ol")
    olGapWidth = parseFloat(olStyle, "gapWidth").toInt()

    val ulStyle = style.getMap("ul")
    ulBulletColor = parseColor(ulStyle, "bulletColor")
    ulGapWidth = parseFloat(ulStyle, "gapWidth").toInt()
    ulMarginLeft = parseFloat(ulStyle, "marginLeft").toInt()
    ulBulletSize = parseFloat(ulStyle, "bulletSize").toInt()

    val imgStyle = style.getMap("img")
    imgWidth = parseFloat(imgStyle, "width").toInt()
    imgHeight = parseFloat(imgStyle, "height").toInt()

    val aStyle = style.getMap("a")
    aColor = parseColor(aStyle, "color")
    aUnderline = parseIsUnderline(aStyle)

    val codeBlockStyle = style.getMap("codeblock")
    codeBlockRadius = parseFloat(codeBlockStyle, "borderRadius")
    codeBlockColor = parseColor(codeBlockStyle, "color")
    codeBlockBackgroundColor = parseColorWithOpacity(codeBlockStyle, "backgroundColor", 80)

    val inlineCodeStyle = style.getMap("code")
    inlineCodeColor = parseColor(inlineCodeStyle, "color")
    inlineCodeBackgroundColor = parseColorWithOpacity(inlineCodeStyle, "backgroundColor", 80)

    val mentionStyle = style.getMap("mention")
    mentionUnderline = parseIsUnderline(mentionStyle)
    mentionColor = parseColor(mentionStyle, "color")
    mentionBackgroundColor = parseColorWithOpacity(mentionStyle, "backgroundColor", 80)
  }

  private fun parseFloat(map: ReadableMap?, key: String): Float {
    val safeMap = ensureValueIsSet(map, key)

    val fontSize = safeMap.getDouble(key)
    return ceil(PixelUtil.toPixelFromSP(fontSize))
  }

  private fun parseColorWithOpacity(map: ReadableMap?, key: String, opacity: Int): Int {
    val color = parseColor(map, key)
    return withOpacity(color, opacity)
  }

  private fun parseColor(map: ReadableMap?, key: String): Int {
    val safeMap = ensureValueIsSet(map, key)

    val color = safeMap.getDouble(key)
    val parsedColor = ColorPropConverter.getColor(color, context)

    return parsedColor
  }

  private fun withOpacity(color: Int, alpha: Int): Int {
    val a = alpha.coerceIn(0, 255)
    return (color and 0x00FFFFFF) or (a shl 24)
  }

  private fun parseIsUnderline(map: ReadableMap?): Boolean {
    val underline = map?.getString("textDecorationLine")
    val isEnabled = underline == "underline"
    val isDisabled = underline == "none"

    if (isEnabled) return true
    if (isDisabled) return false

    throw Error("Specified textDecorationLine value is not supported: $underline. Supported values are 'underline' and 'none'.")
  }

  private fun ensureValueIsSet(map: ReadableMap?, key: String): ReadableMap {
    if (map == null) throw Error("Style map cannot be null")

    if (!map.hasKey(key)) throw Error("Style map must contain key: $key")

    if (map.isNull(key)) throw Error("Style map cannot contain null value for key: $key")

    return map
  }
}
