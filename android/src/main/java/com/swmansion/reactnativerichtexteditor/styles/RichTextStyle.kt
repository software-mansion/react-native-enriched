package com.swmansion.reactnativerichtexteditor.styles

import android.graphics.Color
import com.facebook.react.bridge.ReadableMap
import com.facebook.react.uimanager.PixelUtil
import com.swmansion.reactnativerichtexteditor.ReactNativeRichTextEditorView
import kotlin.Float
import kotlin.Int
import kotlin.String
import kotlin.math.ceil

class RichTextStyle {
  private var mEditorView: ReactNativeRichTextEditorView? = null

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

  constructor(editorView: ReactNativeRichTextEditorView, style: ReadableMap?) {
    mEditorView = editorView

    val h1Style = style?.getMap("h1")
    h1FontSize = parseFloat(h1Style, "fontSize", defaults.h1.fontSize).toInt()

    val h2Style = style?.getMap("h2")
    h2FontSize = parseFloat(h2Style, "fontSize", defaults.h2.fontSize).toInt()

    val h3Style = style?.getMap("h3")
    h3FontSize = parseFloat(h3Style, "fontSize", defaults.h3.fontSize).toInt()

    val blockquoteStyle = style?.getMap("blockquote")
    // TODO: handle blockquote color
    // blockquoteColor = parseColor(blockquoteStyle, "borderColor", defaults.blockquote.color)
    blockquoteGapWidth = parseFloat(blockquoteStyle, "gapWidth", defaults.blockquote.gapWidth).toInt()
    blockquoteStripeWidth = parseFloat(blockquoteStyle, "borderWidth", defaults.blockquote.stripeWidth).toInt()

    val olStyle = style?.getMap("ol")
    olGapWidth = parseFloat(olStyle, "gapWidth", defaults.ol.gapWidth).toInt()
    olMarginLeft = parseFloat(olStyle, "marginLeft", defaults.ol.marginLeft).toInt()

    val ulStyle = style?.getMap("ul")
    // TODO: handle ul bullet color
    ulGapWidth = parseFloat(ulStyle, "gapWidth", defaults.ul.gapWidth).toInt()
    ulMarginLeft = parseFloat(ulStyle, "marginLeft", defaults.ul.marginLeft).toInt()
    ulBulletSize = parseFloat(ulStyle, "bulletSize", defaults.ul.bulletSize).toInt()
  }

  private fun parseFloat(map: ReadableMap?, key: String, defaultValue: Float): Float {
    if (map == null) return defaultValue

    if (!map.hasKey(key)) return defaultValue

    if (map.isNull(key)) return defaultValue

    val fontSize = map.getDouble(key)
    return ceil(PixelUtil.toPixelFromSP(fontSize))
  }

  companion object {
    data class HeadingStyle(val fontSize: Float)
    data class BlockQuoteStyle(val color: Int, val stripeWidth: Float, val gapWidth: Float)
    data class OlStyle(val gapWidth: Float, val marginLeft: Float)
    data class UlStyle(val gapWidth: Float, val marginLeft: Float, val bulletSize: Float, val bulletColor: Int)

    data class Defaults(
      val h1: HeadingStyle,
      val h2: HeadingStyle,
      val h3: HeadingStyle,
      val blockquote: BlockQuoteStyle,
      val ol: OlStyle,
      val ul: UlStyle
    )

    val defaults = Defaults(
      h1 = HeadingStyle(72f),
      h2 = HeadingStyle(64f),
      h3 = HeadingStyle(56f),
      blockquote = BlockQuoteStyle(Color.GRAY, 8f, 24f),
      ol = OlStyle(30f, 40f),
      ul = UlStyle(30f, 26f, 20f, Color.BLACK)
    )
  }
}
