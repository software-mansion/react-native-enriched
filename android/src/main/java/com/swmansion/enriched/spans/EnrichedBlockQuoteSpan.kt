package com.swmansion.enriched.spans

import android.graphics.Canvas
import android.graphics.Paint
import android.text.Layout
import android.text.TextPaint
import android.text.style.LeadingMarginSpan
import android.text.style.MetricAffectingSpan
import com.swmansion.enriched.spans.interfaces.EnrichedBlockSpan
import com.swmansion.enriched.styles.HtmlStyle

// https://android.googlesource.com/platform/frameworks/base/+/refs/heads/main/core/java/android/text/style/QuoteSpan.java
class EnrichedBlockQuoteSpan(
  private val htmlStyle: HtmlStyle,
) : MetricAffectingSpan(),
  LeadingMarginSpan,
  EnrichedBlockSpan {
  override val dependsOnHtmlStyle: Boolean = true

  override fun updateMeasureState(p0: TextPaint) {
    // Do nothing, but inform layout that this span affects text metrics
  }

  override fun getLeadingMargin(p0: Boolean): Int = htmlStyle.blockquoteStripeWidth + htmlStyle.blockquoteGapWidth

  override fun drawLeadingMargin(
    c: Canvas,
    p: Paint,
    x: Int,
    dir: Int,
    top: Int,
    baseline: Int,
    bottom: Int,
    text: CharSequence?,
    start: Int,
    end: Int,
    first: Boolean,
    layout: Layout?,
  ) {
    val style = p.style
    val color = p.color
    p.style = Paint.Style.FILL
    p.color = htmlStyle.blockquoteBorderColor
    c.drawRect(x.toFloat(), top.toFloat(), x + dir * htmlStyle.blockquoteStripeWidth.toFloat(), bottom.toFloat(), p)
    p.style = style
    p.color = color
  }

  override fun updateDrawState(textPaint: TextPaint?) {
    val color = htmlStyle.blockquoteColor
    if (color != null) {
      textPaint?.color = color
    }
  }

  override fun rebuildWithStyle(htmlStyle: HtmlStyle): EnrichedBlockQuoteSpan = EnrichedBlockQuoteSpan(htmlStyle)
}
