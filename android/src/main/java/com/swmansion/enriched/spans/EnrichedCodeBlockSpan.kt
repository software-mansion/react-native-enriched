package com.swmansion.enriched.spans

import android.graphics.Canvas
import android.graphics.Paint
import android.graphics.RectF
import android.graphics.Typeface
import android.text.TextPaint
import android.text.style.LineBackgroundSpan
import android.text.style.MetricAffectingSpan
import com.swmansion.enriched.spans.interfaces.EnrichedBlockSpan
import com.swmansion.enriched.styles.HtmlStyle

class EnrichedCodeBlockSpan(private val htmlStyle: HtmlStyle) : MetricAffectingSpan(), LineBackgroundSpan, EnrichedBlockSpan {
  override fun updateDrawState(paint: TextPaint) {
    paint.typeface = Typeface.MONOSPACE
    paint.color = htmlStyle.codeBlockColor
  }

  override fun updateMeasureState(paint: TextPaint) {
    paint.typeface = Typeface.MONOSPACE
  }

  override fun drawBackground(
    canvas: Canvas,
    p: Paint,
    left: Int,
    right: Int,
    top: Int,
    baseline: Int,
    bottom: Int,
    text: CharSequence,
    start: Int,
    end: Int,
    lineNum: Int
  ) {
    val previousColor = p.color
    p.color = htmlStyle.codeBlockBackgroundColor
    val rect = RectF(left.toFloat(), top.toFloat(), right.toFloat(), bottom.toFloat())
    canvas.drawRoundRect(rect, htmlStyle.codeBlockRadius, htmlStyle.codeBlockRadius, p)
    p.color = previousColor
  }
}
