package com.swmansion.enriched.spans

import android.graphics.Typeface
import android.text.TextPaint
import android.text.style.AbsoluteSizeSpan
import com.swmansion.enriched.spans.interfaces.EnrichedHeadingSpan
import com.swmansion.enriched.styles.HtmlStyle

class EnrichedH3Span(private val htmlStyle: HtmlStyle) : AbsoluteSizeSpan(htmlStyle.h3FontSize), EnrichedHeadingSpan {
  override val dependsOnHtmlStyle: Boolean = true

  override fun updateDrawState(tp: TextPaint) {
    super.updateDrawState(tp)
    val bold = htmlStyle.h3Bold
    if (bold) {
      tp.typeface = Typeface.create(tp.typeface, Typeface.BOLD)
    }
  }

  override fun rebuildWithStyle(htmlStyle: HtmlStyle): EnrichedH3Span {
    return EnrichedH3Span(htmlStyle)
  }
}
