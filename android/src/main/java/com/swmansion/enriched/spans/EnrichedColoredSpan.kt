package com.swmansion.enriched.spans

import android.text.style.ForegroundColorSpan
import com.swmansion.enriched.spans.interfaces.EnrichedInlineSpan
import com.swmansion.enriched.styles.HtmlStyle

class EnrichedColoredSpan(
  htmlStyle: HtmlStyle,
  val color: Int,
) : ForegroundColorSpan(color),
  EnrichedInlineSpan {
  override val dependsOnHtmlStyle: Boolean = false

  override fun rebuildWithStyle(htmlStyle: HtmlStyle): EnrichedColoredSpan = EnrichedColoredSpan(htmlStyle, color)

  fun getHexColor(): String {
    val rgb = foregroundColor and 0x00FFFFFF
    return String.format("#%06X", rgb)
  }
}
