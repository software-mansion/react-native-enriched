package com.swmansion.enriched.text

import android.graphics.Color
import com.facebook.react.bridge.ColorPropConverter
import com.facebook.react.bridge.ReactContext
import com.facebook.react.bridge.ReadableMap
import com.facebook.react.uimanager.PixelUtil
import com.facebook.react.views.text.ReactTypefaceUtils.parseFontWeight
import com.swmansion.enriched.common.EnrichedStyle
import com.swmansion.enriched.common.MentionStyle
import kotlin.math.ceil

data class EnrichedTextStyle(
  // Headings
  override val h1FontSize: Int,
  override val h1Bold: Boolean,
  override val h2FontSize: Int,
  override val h2Bold: Boolean,
  override val h3FontSize: Int,
  override val h3Bold: Boolean,
  override val h4FontSize: Int,
  override val h4Bold: Boolean,
  override val h5FontSize: Int,
  override val h5Bold: Boolean,
  override val h6FontSize: Int,
  override val h6Bold: Boolean,
  // Blockquote
  override val blockquoteColor: Int?,
  override val blockquoteBorderColor: Int,
  override val blockquoteStripeWidth: Int,
  override val blockquoteGapWidth: Int,
  // Ordered List
  override val olGapWidth: Int,
  override val olMarginLeft: Int,
  override val olMarkerFontWeight: Int?,
  override val olMarkerColor: Int?,
  // Unordered List
  override val ulGapWidth: Int,
  override val ulMarginLeft: Int,
  override val ulBulletSize: Int,
  override val ulBulletColor: Int,
  // Checkbox List
  override val ulCheckboxBoxColor: Int,
  override val ulCheckboxBoxSize: Int,
  override val ulCheckboxGapWidth: Int,
  override val ulCheckboxMarginLeft: Int,
  // Links
  override val aColor: Int,
  override val aUnderline: Boolean,
  // Code Blocks
  override val codeBlockColor: Int,
  override val codeBlockBackgroundColor: Int,
  override val codeBlockRadius: Float,
  // Inline Code
  override val inlineCodeColor: Int,
  override val inlineCodeBackgroundColor: Int,
  // Mentions
  override val mentionsStyle: Map<String, MentionStyle>,
) : EnrichedStyle {
  companion object {
    fun fromReadableMap(
      context: ReactContext,
      fontSize: Int,
      map: ReadableMap,
    ): EnrichedTextStyle {
      val h1 = map.getMap("h1")
      val h2 = map.getMap("h2")
      val h3 = map.getMap("h3")
      val h4 = map.getMap("h4")
      val h5 = map.getMap("h5")
      val h6 = map.getMap("h6")
      val blockquote = map.getMap("blockquote")
      val orderedList = map.getMap("ol")
      val unorderedList = map.getMap("ul")
      val checkboxList = map.getMap("ulCheckbox")
      val link = map.getMap("a")
      val codeblock = map.getMap("codeblock")
      val inlineCode = map.getMap("code")
      val mentions = map.getMap("mention")

      return EnrichedTextStyle(
        h1FontSize = parseFloat(h1, "fontSize").toInt(),
        h1Bold = h1?.getBoolean("bold") ?: false,
        h2FontSize = parseFloat(h2, "fontSize").toInt(),
        h2Bold = h2?.getBoolean("bold") ?: false,
        h3FontSize = parseFloat(h3, "fontSize").toInt(),
        h3Bold = h3?.getBoolean("bold") ?: false,
        h4FontSize = parseFloat(h4, "fontSize").toInt(),
        h4Bold = h4?.getBoolean("bold") ?: false,
        h5FontSize = parseFloat(h5, "fontSize").toInt(),
        h5Bold = h5?.getBoolean("bold") ?: false,
        h6FontSize = parseFloat(h6, "fontSize").toInt(),
        h6Bold = h6?.getBoolean("bold") ?: false,
        blockquoteColor = parseOptionalColor(context, blockquote, "color"),
        blockquoteBorderColor = parseColor(context, blockquote, "borderColor"),
        blockquoteStripeWidth = parseFloat(blockquote, "borderWidth").toInt(),
        blockquoteGapWidth = parseFloat(blockquote, "gapWidth").toInt(),
        olGapWidth = parseFloat(orderedList, "gapWidth").toInt(),
        olMarginLeft = calculateOlMarginLeft(fontSize, parseFloat(orderedList, "marginLeft").toInt()),
        olMarkerFontWeight = parseOptionalFontWeight(orderedList, "markerFontWeight"),
        olMarkerColor = parseOptionalColor(context, orderedList, "markerColor"),
        ulGapWidth = parseFloat(unorderedList, "gapWidth").toInt(),
        ulMarginLeft = parseFloat(unorderedList, "marginLeft").toInt(),
        ulBulletSize = parseFloat(unorderedList, "bulletSize").toInt(),
        ulBulletColor = parseColor(context, unorderedList, "bulletColor"),
        ulCheckboxBoxColor = parseColor(context, checkboxList, "boxColor"),
        ulCheckboxBoxSize = parseFloat(checkboxList, "boxSize").toInt(),
        ulCheckboxGapWidth = parseFloat(checkboxList, "gapWidth").toInt(),
        ulCheckboxMarginLeft = parseFloat(checkboxList, "marginLeft").toInt(),
        aColor = parseColor(context, link, "color"),
        aUnderline = parseIsUnderline(link),
        codeBlockColor = parseColor(context, codeblock, "color"),
        codeBlockBackgroundColor = parseColorWithOpacity(context, codeblock, "backgroundColor", 80),
        codeBlockRadius = parseFloat(codeblock, "borderRadius"),
        inlineCodeColor = parseColor(context, inlineCode, "color"),
        inlineCodeBackgroundColor = parseColorWithOpacity(context, inlineCode, "backgroundColor", 80),
        mentionsStyle = parseMentionsStyle(context, mentions),
      )
    }

    private fun parseFloat(
      map: ReadableMap?,
      key: String,
    ): Float {
      if (map == null || !map.hasKey(key) || map.isNull(key)) return 0f
      return ceil(PixelUtil.toPixelFromSP(map.getDouble(key)))
    }

    private fun parseColor(
      context: ReactContext,
      map: ReadableMap?,
      key: String,
    ): Int {
      val colorDouble = map?.getDouble(key) ?: throw Error("Key $key is missing or null")
      return ColorPropConverter.getColor(colorDouble, context) ?: Color.BLACK
    }

    private fun parseOptionalColor(
      context: ReactContext,
      map: ReadableMap?,
      key: String,
    ): Int? {
      if (map == null || !map.hasKey(key) || map.isNull(key)) return null
      return ColorPropConverter.getColor(map.getDouble(key), context)
    }

    private fun parseColorWithOpacity(
      context: ReactContext,
      map: ReadableMap?,
      key: String,
      opacity: Int,
    ): Int {
      val color = parseColor(context, map, key)
      if (Color.alpha(color) == 0) return color
      return (color and 0x00FFFFFF) or (opacity.coerceIn(0, 255) shl 24)
    }

    private fun parseIsUnderline(map: ReadableMap?): Boolean = map?.getString("textDecorationLine") == "underline"

    private fun parseOptionalFontWeight(
      map: ReadableMap?,
      key: String,
    ): Int? {
      val weight = map?.getString(key) ?: return null
      return parseFontWeight(weight)
    }

    private fun calculateOlMarginLeft(
      fontSize: Int,
      userMargin: Int,
    ): Int {
      val leadMargin = fontSize / 2
      return leadMargin + userMargin
    }

    private fun parseMentionsStyle(
      context: ReactContext,
      map: ReadableMap?,
    ): Map<String, MentionStyle> {
      val result = mutableMapOf<String, MentionStyle>()
      val iterator = map?.keySetIterator() ?: return result
      while (iterator.hasNextKey()) {
        val key = iterator.nextKey()
        val value = map.getMap(key) ?: continue
        result[key] =
          MentionStyle(
            color = parseColor(context, value, "color"),
            backgroundColor = parseColorWithOpacity(context, value, "backgroundColor", 80),
            underline = parseIsUnderline(value),
          )
      }
      return result
    }
  }
}
