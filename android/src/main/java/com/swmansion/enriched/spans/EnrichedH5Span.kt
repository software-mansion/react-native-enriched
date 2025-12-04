package com.swmansion.enriched.spans

import android.graphics.Typeface
import android.text.TextPaint
import android.text.style.AbsoluteSizeSpan
import com.swmansion.enriched.spans.interfaces.EnrichedHeadingSpan
import com.swmansion.enriched.styles.HtmlStyle

class EnrichedH5Span(private val htmlStyle: HtmlStyle) : AbsoluteSizeSpan(htmlStyle.h5FontSize), EnrichedHeadingSpan {
  override fun updateDrawState(tp: TextPaint) {
    super.updateDrawState(tp)
    val bold = htmlStyle.h5Bold
    if (bold) {
      tp.typeface = Typeface.create(tp.typeface, Typeface.BOLD)
    }
  }
}
