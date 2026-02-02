package com.swmansion.enriched.common.spans

import android.graphics.Typeface
import android.text.TextPaint
import android.text.style.AbsoluteSizeSpan
import com.swmansion.enriched.common.EnrichedStyle
import com.swmansion.enriched.common.spans.interfaces.EnrichedHeadingSpan
import com.swmansion.enriched.textinput.styles.HtmlStyle

open class EnrichedH4Span(
  private val enrichedStyle: EnrichedStyle,
) : AbsoluteSizeSpan(enrichedStyle.h4FontSize),
  EnrichedHeadingSpan {
  override fun updateDrawState(tp: TextPaint) {
    super.updateDrawState(tp)
    val bold = enrichedStyle.h4Bold
    if (bold) {
      tp.typeface = Typeface.create(tp.typeface, Typeface.BOLD)
    }
  }
}
