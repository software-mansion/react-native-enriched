package com.swmansion.enriched.spans

import android.graphics.Typeface
import android.text.TextPaint
import android.text.style.AbsoluteSizeSpan
import com.swmansion.enriched.spans.interfaces.EnrichedHeadingSpan
import com.swmansion.enriched.styles.HtmlStyle

class EnrichedH6Span(
  private val htmlStyle: HtmlStyle,
) : AbsoluteSizeSpan(htmlStyle.h6FontSize),
  EnrichedHeadingSpan {
  override val dependsOnHtmlStyle: Boolean = true

  override fun updateDrawState(tp: TextPaint) {
    super.updateDrawState(tp)
    val bold = htmlStyle.h6Bold
    if (bold) {
      tp.typeface = Typeface.create(tp.typeface, Typeface.BOLD)
    }
  }

  override fun rebuildWithStyle(htmlStyle: HtmlStyle): EnrichedH6Span = EnrichedH6Span(htmlStyle)
}
