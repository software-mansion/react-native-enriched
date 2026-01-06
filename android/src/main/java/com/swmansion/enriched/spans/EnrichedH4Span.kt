package com.swmansion.enriched.spans

import android.graphics.Typeface
import android.text.TextPaint
import android.text.style.AbsoluteSizeSpan
import com.swmansion.enriched.spans.interfaces.EnrichedHeadingSpan
import com.swmansion.enriched.styles.HtmlStyle

class EnrichedH4Span(
  private val htmlStyle: HtmlStyle,
) : AbsoluteSizeSpan(htmlStyle.h4FontSize),
  EnrichedHeadingSpan {
  override val dependsOnHtmlStyle: Boolean = true

  override fun updateDrawState(tp: TextPaint) {
    super.updateDrawState(tp)
    val bold = htmlStyle.h4Bold
    if (bold) {
      tp.typeface = Typeface.create(tp.typeface, Typeface.BOLD)
    }
  }

  override fun rebuildWithStyle(htmlStyle: HtmlStyle): EnrichedH4Span = EnrichedH4Span(htmlStyle)
}
