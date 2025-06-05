package com.swmansion.reactnativerichtexteditor.styles

import android.graphics.Color
import com.facebook.react.bridge.ColorPropConverter
import com.facebook.react.bridge.ReactContext
import com.facebook.react.bridge.ReadableMap
import com.facebook.react.uimanager.PixelUtil
import com.swmansion.reactnativerichtexteditor.ReactNativeRichTextEditorView
import kotlin.Float
import kotlin.Int
import kotlin.String
import kotlin.math.ceil

class RichTextStyle {
  private var style: ReadableMap? = null
  private var editorView: ReactNativeRichTextEditorView? = null

  // Default values are ignored as they are specified on the JS side.
  // They are specified only because they are required by the constructor.
  // JS passes them as a prop - so they are initialized after the constructor is called.
  var h1FontSize: Int = 72
  var h2FontSize: Int = 64
  var h3FontSize: Int = 56

  var blockquoteColor: Int = Color.BLACK
  var blockquoteStripeWidth: Int = 2
  var blockquoteGapWidth: Int = 16

  var olGapWidth: Int = 16
  var olMarginLeft: Int = 24

  var ulGapWidth: Int = 16
  var ulMarginLeft: Int = 24
  var ulBulletSize: Int = 8
  var ulBulletColor: Int = Color.BLACK

  var imgWidth: Int = 200
  var imgHeight: Int = 200

  var aColor: Int = Color.BLACK
  var aUnderline: Boolean = true

  var codeBlockColor: Int = Color.BLACK
  var codeBlockBackgroundColor: Int = Color.BLACK
  var codeBlockRadius: Float = 4f

  var inlineCodeColor: Int = Color.BLACK
  var inlineCodeBackgroundColor: Int = Color.BLACK

  var mentionsStyle: MutableMap<String, MentionStyle> = mutableMapOf()

  constructor(editorView: ReactNativeRichTextEditorView, style: ReadableMap?) {
    this.editorView = editorView
    this.style = style

    invalidateStyles()
  }

  fun invalidateStyles() {
    val style = this.style ?: return

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
    val userDefinedMarginLeft = parseFloat(olStyle, "marginLeft").toInt()
    val calculatedMarginLeft = calculateOlMarginLeft(editorView, userDefinedMarginLeft)
    olMarginLeft = calculatedMarginLeft
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
    mentionsStyle = parseMentionsStyle(mentionStyle)
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
    val parsedColor = ColorPropConverter.getColor(color, editorView?.context as ReactContext)

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

  private fun calculateOlMarginLeft(editorView: ReactNativeRichTextEditorView?, userMargin: Int): Int {
    val fontSize = editorView?.fontSize?.toInt() ?: 0
    val leadMargin = fontSize / 2

    return leadMargin + userMargin
  }

  private fun ensureValueIsSet(map: ReadableMap?, key: String): ReadableMap {
    if (map == null) throw Error("Style map cannot be null")

    if (!map.hasKey(key)) throw Error("Style map must contain key: $key")

    if (map.isNull(key)) throw Error("Style map cannot contain null value for key: $key")

    return map
  }

  private fun parseMentionsStyle(mentionsStyle: ReadableMap?): MutableMap<String, MentionStyle> {
    if (mentionsStyle == null) throw Error("Mentions style cannot be null")

    val parsedMentionsStyle: MutableMap<String, MentionStyle> = mutableMapOf()

     val iterator = mentionsStyle.keySetIterator()
        while (iterator.hasNextKey()) {
          val key = iterator.nextKey()
          val value = mentionsStyle.getMap(key)

          if (value == null) throw Error("Mention style for key '$key' cannot be null")

          val color = parseColor(value, "color")
          val backgroundColor = parseColorWithOpacity(value, "backgroundColor", 80)
          val isUnderline = parseIsUnderline(value)
          val parsedStyle = MentionStyle(color, backgroundColor, isUnderline)
          parsedMentionsStyle.put(key, parsedStyle)
        }

    return parsedMentionsStyle
  }

  companion object {
    data class MentionStyle(
      val color: Int,
      val backgroundColor: Int,
      val underline: Boolean
    )
  }
}
