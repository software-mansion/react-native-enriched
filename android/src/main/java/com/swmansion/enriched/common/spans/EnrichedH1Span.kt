package com.swmansion.enriched.common.spans

import android.graphics.Typeface
import android.text.TextPaint
import android.text.style.AbsoluteSizeSpan
import com.swmansion.enriched.common.EnrichedStyle
import com.swmansion.enriched.common.spans.interfaces.EnrichedHeadingSpan

open class EnrichedH1Span(
  private val enrichedStyle: EnrichedStyle,
) : AbsoluteSizeSpan(enrichedStyle.h1FontSize),
  EnrichedHeadingSpan {
  override fun updateDrawState(tp: TextPaint) {
    super.updateDrawState(tp)
    val bold = enrichedStyle.h1Bold
    if (bold) {
      tp.typeface = Typeface.create(tp.typeface, Typeface.BOLD)
    }
  }
}
