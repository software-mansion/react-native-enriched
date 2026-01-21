package com.swmansion.enriched.textinput.spans

import android.graphics.Typeface
import android.text.TextPaint
import android.text.style.AbsoluteSizeSpan
import com.swmansion.enriched.textinput.spans.interfaces.EnrichedHeadingSpan
import com.swmansion.enriched.textinput.styles.HtmlStyle

class EnrichedH2Span(
  private val htmlStyle: HtmlStyle,
) : AbsoluteSizeSpan(htmlStyle.h2FontSize),
  EnrichedHeadingSpan {
  override val dependsOnHtmlStyle: Boolean = true

  override fun updateDrawState(tp: TextPaint) {
    super.updateDrawState(tp)
    val bold = htmlStyle.h2Bold
    if (bold) {
      tp.typeface = Typeface.create(tp.typeface, Typeface.BOLD)
    }
  }

  override fun rebuildWithStyle(htmlStyle: HtmlStyle): EnrichedH2Span = EnrichedH2Span(htmlStyle)
}
