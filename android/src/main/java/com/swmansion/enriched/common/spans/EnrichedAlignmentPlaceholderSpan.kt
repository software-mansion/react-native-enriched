package com.swmansion.enriched.textinput.spans

import android.graphics.Canvas
import android.graphics.Paint
import android.text.style.ReplacementSpan

class EnrichedAlignmentPlaceholderSpan : ReplacementSpan() {
  override fun getSize(
    paint: Paint,
    text: CharSequence,
    start: Int,
    end: Int,
    fm: Paint.FontMetricsInt?,
  ): Int = paint.measureText(" ").toInt()

  override fun draw(
    canvas: Canvas,
    text: CharSequence,
    start: Int,
    end: Int,
    x: Float,
    top: Int,
    y: Int,
    bottom: Int,
    paint: Paint,
  ) {
  }
}
