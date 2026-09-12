package com.swmansion.enriched.common.spans

import android.graphics.Canvas
import android.graphics.Paint
import android.graphics.Typeface
import android.os.Build
import android.text.Layout
import android.text.TextPaint
import android.text.style.LeadingMarginSpan
import android.text.style.MetricAffectingSpan
import com.swmansion.enriched.common.EnrichedStyle
import com.swmansion.enriched.common.spans.interfaces.EnrichedParagraphSpan
import kotlin.math.ceil
import kotlin.math.max

open class EnrichedOrderedListSpan(
  var index: Int,
  private val enrichedStyle: EnrichedStyle,
) : MetricAffectingSpan(),
  LeadingMarginSpan,
  EnrichedParagraphSpan {
  var columnMargin = enrichedStyle.olMarginLeft

  // Computes the marker column width from the widest marker in the list ("<highestIndex>.").
  // Returns true when the column width actually changed, so callers can force a relayout.
  fun updateColumnMargin(
    paint: Paint,
    highestIndex: Int,
  ): Boolean {
    val (digitWidth, dotWidth) = markerMetricsFor(paint, paint.typeface)
    val highestIndexWidth = ceil(digitCountOf(highestIndex) * digitWidth + dotWidth).toInt()

    val newColumnMargin = max(enrichedStyle.olMarginLeft, highestIndexWidth)
    if (newColumnMargin == columnMargin) return false
    columnMargin = newColumnMargin
    return true
  }

  override fun updateMeasureState(p0: TextPaint) {
    // Do nothing, but inform layout that this span affects text metrics
  }

  override fun updateDrawState(p0: TextPaint?) {
    // Do nothing, but inform layout that this span affects text metrics
  }

  override fun getLeadingMargin(first: Boolean): Int = columnMargin + enrichedStyle.olGapWidth

  override fun drawLeadingMargin(
    canvas: Canvas,
    paint: Paint,
    x: Int,
    dir: Int,
    top: Int,
    baseline: Int,
    bottom: Int,
    t: CharSequence?,
    start: Int,
    end: Int,
    first: Boolean,
    layout: Layout?,
  ) {
    if (first) {
      val originalColor = paint.color
      val originalTypeface = paint.typeface
      paint.color = enrichedStyle.olMarkerColor ?: originalColor
      paint.typeface = getTypeface(enrichedStyle.olMarkerFontWeight, originalTypeface)

      val text = "$index."
      val width = paint.measureText(text)

      val yPosition = baseline.toFloat()
      val xPosition = (columnMargin + x - width) * dir

      canvas.drawText(text, xPosition, yPosition, paint)

      paint.color = originalColor
      paint.typeface = originalTypeface
    }
  }

  private fun getTypeface(
    fontWeight: Int?,
    originalTypeface: Typeface,
  ): Typeface =
    if (fontWeight == null) {
      originalTypeface
    } else if (Build.VERSION.SDK_INT >= 28) {
      Typeface.create(originalTypeface, fontWeight, false)
    } else {
      // Fallback for API < 28: only bold/normal supported
      if (fontWeight == Typeface.BOLD) {
        Typeface.create(originalTypeface, Typeface.BOLD)
      } else {
        Typeface.create(originalTypeface, Typeface.NORMAL)
      }
    }

  private fun markerMetricsFor(
    paint: Paint,
    baseTypeface: Typeface,
  ): Pair<Float, Float> {
    val key = MarkerMetricsKey(baseTypeface, enrichedStyle.olMarkerFontWeight, paint.textSize)
    return markerMetricsCache.getOrPut(key) {
      val originalTypeface = paint.typeface
      paint.typeface = getTypeface(enrichedStyle.olMarkerFontWeight, baseTypeface)
      val digitWidth = paint.measureText("0")
      val dotWidth = paint.measureText(".")
      paint.typeface = originalTypeface
      Pair(digitWidth, dotWidth)
    }
  }

  private data class MarkerMetricsKey(
    val baseTypeface: Typeface,
    val fontWeight: Int?,
    val textSize: Float,
  )

  companion object {
    private val markerMetricsCache = mutableMapOf<MarkerMetricsKey, Pair<Float, Float>>()

    private fun digitCountOf(n: Int): Int {
      var count = 1
      var value = max(n, 1)
      while (value >= 10) {
        value /= 10
        count++
      }
      return count
    }
  }
}
