package com.swmansion.enriched.common.spans

import android.graphics.Typeface
import android.text.TextPaint
import android.text.style.AbsoluteSizeSpan
import com.swmansion.enriched.common.EnrichedStyle
import com.swmansion.enriched.common.spans.interfaces.EnrichedHeadingSpan

open class EnrichedH3Span(
  private val enrichedStyle: EnrichedStyle,
) : AbsoluteSizeSpan(enrichedStyle.h3FontSize),
  EnrichedHeadingSpan {
  override fun updateDrawState(tp: TextPaint) {
    super.updateDrawState(tp)
    val bold = enrichedStyle.h3Bold
    if (bold) {
      tp.typeface = Typeface.create(tp.typeface, Typeface.BOLD)
    }
  }
}
