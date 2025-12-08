package com.swmansion.enriched.spans

import android.graphics.Typeface
import android.text.TextPaint
import android.text.style.MetricAffectingSpan
import com.swmansion.enriched.spans.interfaces.EnrichedInlineSpan
import com.swmansion.enriched.styles.HtmlStyle

class EnrichedInlineCodeSpan(private val htmlStyle: HtmlStyle) : MetricAffectingSpan(), EnrichedInlineSpan {
  override val dependsOnHtmlStyle: Boolean = true

  override fun updateDrawState(textPaint: TextPaint) {
    val typeface = Typeface.create(Typeface.MONOSPACE, Typeface.NORMAL)
    textPaint.typeface = typeface
    textPaint.color = htmlStyle.inlineCodeColor
    textPaint.bgColor = htmlStyle.inlineCodeBackgroundColor
  }

  override fun updateMeasureState(textPaint: TextPaint) {
    val typeface = Typeface.create(Typeface.MONOSPACE, Typeface.NORMAL)
    textPaint.typeface = typeface
  }

  override fun rebuildWithStyle(htmlStyle: HtmlStyle): EnrichedInlineCodeSpan {
    return EnrichedInlineCodeSpan(htmlStyle)
  }
}
