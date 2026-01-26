package com.swmansion.enriched.common.spans

import android.graphics.Typeface
import android.text.TextPaint
import android.text.style.MetricAffectingSpan
import com.swmansion.enriched.common.EnrichedStyle
import com.swmansion.enriched.common.spans.interfaces.EnrichedInlineSpan

open class EnrichedInlineCodeSpan(
  private val enrichedStyle: EnrichedStyle,
) : MetricAffectingSpan(),
  EnrichedInlineSpan {
  override fun updateDrawState(textPaint: TextPaint) {
    val typeface = Typeface.create(Typeface.MONOSPACE, Typeface.NORMAL)
    textPaint.typeface = typeface
    textPaint.color = enrichedStyle.inlineCodeColor
    textPaint.bgColor = enrichedStyle.inlineCodeBackgroundColor
  }

  override fun updateMeasureState(textPaint: TextPaint) {
    val typeface = Typeface.create(Typeface.MONOSPACE, Typeface.NORMAL)
    textPaint.typeface = typeface
  }
}
