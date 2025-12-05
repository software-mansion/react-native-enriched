package com.swmansion.enriched.spans

import android.graphics.Canvas
import android.graphics.Paint
import android.graphics.Path
import android.graphics.RectF
import android.graphics.Typeface
import android.text.Spanned
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
    if (text !is Spanned) {
      return
    }

    val previousColor = p.color
    p.color = htmlStyle.codeBlockBackgroundColor

    val radius = htmlStyle.codeBlockRadius

    val spanStart = text.getSpanStart(this)
    val spanEnd = text.getSpanEnd(this)
    val isFirstLineOfSpan = start == spanStart
    val isLastLineOfSpan = end == spanEnd || (spanEnd + 1 == end && text[spanEnd] == '\n')

    val path = Path()
    val radii = floatArrayOf(0f, 0f, 0f, 0f, 0f, 0f, 0f, 0f)

    if (isFirstLineOfSpan) {
      // Top-Left and Top-Right corners
      radii[0] = radius
      radii[1] = radius
      radii[2] = radius
      radii[3] = radius
    }

    if (isLastLineOfSpan) {
      // Bottom-Right and Bottom-Left corners
      radii[4] = radius
      radii[5] = radius
      radii[6] = radius
      radii[7] = radius
    }

    val rect = RectF(left.toFloat(), top.toFloat(), right.toFloat(), bottom.toFloat())

    path.addRoundRect(rect, radii, Path.Direction.CW)
    canvas.drawPath(path, p)
    p.color = previousColor
  }
}
