package com.swmansion.enriched.textinput.spans

import android.graphics.Typeface
import android.text.style.StyleSpan
import com.swmansion.enriched.textinput.spans.interfaces.EnrichedInlineSpan
import com.swmansion.enriched.textinput.styles.HtmlStyle

@Suppress("UNUSED_PARAMETER")
class EnrichedItalicSpan(
  private val htmlStyle: HtmlStyle,
) : StyleSpan(Typeface.ITALIC),
  EnrichedInlineSpan {
  override val dependsOnHtmlStyle: Boolean = false

  override fun rebuildWithStyle(htmlStyle: HtmlStyle): EnrichedItalicSpan = EnrichedItalicSpan(htmlStyle)
}
