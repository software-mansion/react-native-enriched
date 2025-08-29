package com.swmansion.enriched.spans

import android.graphics.Typeface
import android.text.TextPaint
import android.text.style.BackgroundColorSpan
import com.swmansion.enriched.spans.interfaces.EnrichedInlineSpan
import com.swmansion.enriched.styles.HtmlStyle

class EnrichedInlineCodeSpan(private val htmlStyle: HtmlStyle) : BackgroundColorSpan(htmlStyle.inlineCodeBackgroundColor), EnrichedInlineSpan {
  override fun updateDrawState(textPaint: TextPaint) {
    super.updateDrawState(textPaint)

    textPaint.color = htmlStyle.inlineCodeColor
    textPaint.typeface = Typeface.create(Typeface.MONOSPACE, Typeface.NORMAL)
  }
}
