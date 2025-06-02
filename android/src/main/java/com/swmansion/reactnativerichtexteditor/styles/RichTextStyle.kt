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

  var h1FontSize: Int = defaults.h1.fontSize.toInt()
  var h2FontSize: Int = defaults.h2.fontSize.toInt()
  var h3FontSize: Int = defaults.h3.fontSize.toInt()

  var blockquoteColor: Int = defaults.blockquote.color
  var blockquoteStripeWidth: Int = defaults.blockquote.stripeWidth.toInt()
  var blockquoteGapWidth: Int = defaults.blockquote.gapWidth.toInt()

  var olGapWidth: Int = defaults.ol.gapWidth.toInt()
  var olMarginLeft: Int = defaults.ol.marginLeft.toInt()

  var ulGapWidth: Int = defaults.ul.gapWidth.toInt()
  var ulMarginLeft: Int = defaults.ul.marginLeft.toInt()
  var ulBulletSize: Int = defaults.ul.bulletSize.toInt()
  var ulBulletColor: Int = defaults.ul.bulletColor

  var imgWidth: Int = defaults.img.width.toInt()
  var imgHeight: Int = defaults.img.height.toInt()

  var aColor: Int = defaults.a.color
  var aUnderline: Boolean = defaults.a.underline

  var codeBlockColor: Int = defaults.codeBlock.color
  var codeBlockBackgroundColor: Int = defaults.codeBlock.backgroundColor
  var codeBlockRadius: Float = defaults.codeBlock.radius

  var inlineCodeColor: Int = defaults.inlineCodeStyle.color
  var inlineCodeBackgroundColor: Int = defaults.inlineCodeStyle.backgroundColor

  var mentionColor: Int = defaults.mentionStyle.color
  var mentionBackgroundColor: Int = defaults.mentionStyle.backgroundColor
  var mentionUnderline: Boolean = defaults.mentionStyle.underline

  constructor(context: ReactContext, style: ReadableMap?) {
    this.context = context

    val h1Style = style?.getMap("h1")
    h1FontSize = parseFloat(h1Style, "fontSize", defaults.h1.fontSize).toInt()

    val h2Style = style?.getMap("h2")
    h2FontSize = parseFloat(h2Style, "fontSize", defaults.h2.fontSize).toInt()

    val h3Style = style?.getMap("h3")
    h3FontSize = parseFloat(h3Style, "fontSize", defaults.h3.fontSize).toInt()

    val blockquoteStyle = style?.getMap("blockquote")
    blockquoteColor = parseColor(blockquoteStyle, "color", defaults.blockquote.color)
    blockquoteGapWidth = parseFloat(blockquoteStyle, "gapWidth", defaults.blockquote.gapWidth).toInt()
    blockquoteStripeWidth = parseFloat(blockquoteStyle, "borderWidth", defaults.blockquote.stripeWidth).toInt()

    val olStyle = style?.getMap("ol")
    olGapWidth = parseFloat(olStyle, "gapWidth", defaults.ol.gapWidth).toInt()
    olMarginLeft = parseFloat(olStyle, "marginLeft", defaults.ol.marginLeft).toInt()

    val ulStyle = style?.getMap("ul")
    ulBulletColor = parseColor(ulStyle, "bulletColor", defaults.ul.bulletColor)
    ulGapWidth = parseFloat(ulStyle, "gapWidth", defaults.ul.gapWidth).toInt()
    ulMarginLeft = parseFloat(ulStyle, "marginLeft", defaults.ul.marginLeft).toInt()
    ulBulletSize = parseFloat(ulStyle, "bulletSize", defaults.ul.bulletSize).toInt()

    val imgStyle = style?.getMap("img")
    imgWidth = parseFloat(imgStyle, "width", defaults.img.width).toInt()
    imgHeight = parseFloat(imgStyle, "height", defaults.img.height).toInt()

    val aStyle = style?.getMap("a")
    aColor = parseColor(aStyle, "color", defaults.a.color)
    aUnderline = parseIsUnderline(aStyle, defaults.a.underline)

    val codeBlockStyle = style?.getMap("codeblock")
    codeBlockRadius = parseFloat(codeBlockStyle, "borderRadius", defaults.codeBlock.radius)
    codeBlockColor = parseColor(codeBlockStyle, "color", defaults.codeBlock.color)
    codeBlockBackgroundColor = parseColorWithOpacity(codeBlockStyle, "backgroundColor", defaults.codeBlock.backgroundColor, 80)

    val inlineCodeStyle = style?.getMap("code")
    inlineCodeColor = parseColor(inlineCodeStyle, "color", defaults.inlineCodeStyle.color)
    inlineCodeBackgroundColor = parseColorWithOpacity(inlineCodeStyle, "backgroundColor", defaults.inlineCodeStyle.backgroundColor, 80)

    val mentionStyle = style?.getMap("mention")
    mentionUnderline = parseIsUnderline(mentionStyle, defaults.mentionStyle.underline)
    mentionColor = parseColor(mentionStyle, "color", defaults.mentionStyle.color)
    mentionBackgroundColor = parseColorWithOpacity(mentionStyle, "backgroundColor", defaults.mentionStyle.backgroundColor, 80)
  }

  private fun parseFloat(map: ReadableMap?, key: String, defaultValue: Float): Float {
    if (map == null) return defaultValue

    if (!map.hasKey(key)) return defaultValue

    if (map.isNull(key)) return defaultValue

    val fontSize = map.getDouble(key)
    return ceil(PixelUtil.toPixelFromSP(fontSize))
  }

  private fun parseColorWithOpacity(map: ReadableMap?, key: String, defaultValue: Int, opacity: Int): Int {
    val color = parseColor(map, key, defaultValue)
    return withOpacity(color, opacity)
  }

  private fun parseColor(map: ReadableMap?, key: String, defaultValue: Int): Int {
    if (map == null) return defaultValue

    if (!map.hasKey(key)) return defaultValue

    if (map.isNull(key)) return defaultValue

    val color = map.getDouble(key)
    val parsedColor = ColorPropConverter.getColor(color, context)

    return parsedColor
  }

  private fun withOpacity(color: Int, alpha: Int): Int {
    val a = alpha.coerceIn(0, 255)
    return (color and 0x00FFFFFF) or (a shl 24)
  }

  private fun parseIsUnderline(map: ReadableMap?, defaultValue: Boolean): Boolean {
    val underline = map?.getString("textDecorationLine")
    val isEnabled = underline == "underline"
    val isDisabled = underline == "none"

    if (isEnabled) return true
    if (isDisabled) return false
    return defaultValue
  }

  companion object {
    data class HeadingStyle(val fontSize: Float)
    data class BlockQuoteStyle(val color: Int, val stripeWidth: Float, val gapWidth: Float)
    data class OlStyle(val gapWidth: Float, val marginLeft: Float)
    data class UlStyle(val gapWidth: Float, val marginLeft: Float, val bulletSize: Float, val bulletColor: Int)
    data class ImgStyle(val width: Float, val height: Float)
    data class AStyle(val color: Int, val underline: Boolean)
    data class CodeBlockStyle(val color: Int, val backgroundColor: Int, val radius: Float)
    data class InlineCodeStyle(val color: Int, val backgroundColor: Int)
    data class MentionStyle(val color: Int, val backgroundColor: Int, val underline: Boolean)

    data class Defaults(
      val h1: HeadingStyle,
      val h2: HeadingStyle,
      val h3: HeadingStyle,
      val blockquote: BlockQuoteStyle,
      val ol: OlStyle,
      val ul: UlStyle,
      val img: ImgStyle,
      val a: AStyle,
      val codeBlock: CodeBlockStyle,
      val inlineCodeStyle: InlineCodeStyle,
      val mentionStyle: MentionStyle,
    )

    val defaults = Defaults(
      h1 = HeadingStyle(72f),
      h2 = HeadingStyle(64f),
      h3 = HeadingStyle(56f),
      blockquote = BlockQuoteStyle(Color.GRAY, 8f, 24f),
      ol = OlStyle(30f, 40f),
      ul = UlStyle(30f, 26f, 20f, Color.BLACK),
      img = ImgStyle(160f, 160f),
      a = AStyle(Color.BLUE, true),
      codeBlock = CodeBlockStyle(Color.BLACK, Color.rgb(250, 250, 250), 8f),
      inlineCodeStyle = InlineCodeStyle(Color.RED, Color.rgb(250, 250, 250)),
      mentionStyle = MentionStyle(Color.BLUE, Color.rgb(0, 0, 255), true)
    )
  }
}
