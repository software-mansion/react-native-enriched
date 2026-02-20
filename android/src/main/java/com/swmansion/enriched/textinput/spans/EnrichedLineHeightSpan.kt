package com.swmansion.enriched.textinput.spans

import android.graphics.Paint
import android.text.Spannable
import android.text.TextPaint
import android.text.style.LineHeightSpan
import android.text.style.MetricAffectingSpan
import com.facebook.react.uimanager.PixelUtil
import com.swmansion.enriched.common.spans.interfaces.EnrichedHeadingSpan

class EnrichedLineHeightSpan(
  val lineHeight: Float,
) : MetricAffectingSpan(),
  LineHeightSpan {
  override fun updateDrawState(p0: TextPaint?) {
    // Do nothing but inform TextView that line height should be recalculated
  }

  override fun updateMeasureState(p0: TextPaint) {
    // Do nothing but inform TextView that line height should be recalculated
  }

  override fun chooseHeight(
    text: CharSequence,
    start: Int,
    end: Int,
    spanstartv: Int,
    v: Int,
    fm: Paint.FontMetricsInt,
  ) {
    val spannable = text as? Spannable ?: return
    // Do not modify line height for headings
    // In the future we may consider adding custom lineHeight support for each paragraph style
    if (spannable.getSpans(start, end, EnrichedHeadingSpan::class.java).isNotEmpty()) return

    val lineHeightPx = PixelUtil.toPixelFromSP(lineHeight)
    val currentHeight = (fm.descent - fm.ascent).toFloat()
    if (lineHeightPx <= currentHeight) return

    val extra = (lineHeightPx - currentHeight).toInt()
    fm.ascent -= extra
    fm.top = minOf(fm.top, fm.ascent)
  }
}
