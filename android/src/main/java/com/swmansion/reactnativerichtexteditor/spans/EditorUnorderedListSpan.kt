package com.swmansion.reactnativerichtexteditor.spans

import android.graphics.Canvas
import android.graphics.Color
import android.graphics.Paint
import android.text.Layout
import android.text.Spanned
import android.text.style.LeadingMarginSpan
import com.swmansion.reactnativerichtexteditor.spans.interfaces.EditorInlineSpan

// https://android.googlesource.com/platform/frameworks/base/+/refs/heads/main/core/java/android/text/style/BulletSpan.java
class EditorUnorderedListSpan : LeadingMarginSpan, EditorInlineSpan {
  private val leadWidth = 26
  private val bulletRadius = 10
  private val gapWidth = 30
  private val wantColor = true

  override fun getLeadingMargin(p0: Boolean): Int {
    return 2 * bulletRadius + gapWidth + leadWidth
  }

  override fun drawLeadingMargin(
    canvas: Canvas,
    paint: Paint,
    x: Int,
    dir: Int,
    top: Int,
    baseline: Int,
    bottom: Int,
    text: CharSequence,
    start: Int,
    end: Int,
    first: Boolean,
    layout: Layout?
  ) {
    val spannedText = text as Spanned

    if (spannedText.getSpanStart(this) == start) {
      val style = paint.style
      var oldColor = 0

      if (wantColor) {
        oldColor = paint.color
        paint.color = Color.BLACK
      }

      paint.style = Paint.Style.FILL

      val yPosition = (top + bottom) / 2f
      val xPosition = x + dir * bulletRadius + leadWidth

      canvas.drawCircle(xPosition.toFloat(), yPosition, bulletRadius.toFloat(), paint)

      if (wantColor) {
        paint.color = oldColor
      }

      paint.style = style
    }
  }
}
