package com.swmansion.reactnativerichtexteditor.spans

import android.graphics.Canvas
import android.graphics.Paint
import android.text.Layout
import android.text.style.LeadingMarginSpan
import com.swmansion.reactnativerichtexteditor.spans.interfaces.EditorInlineSpan
import com.swmansion.reactnativerichtexteditor.styles.RichTextStyle

@Suppress("UNUSED_PARAMETER")
class EditorOrderedListSpan(private var index: Int, private val richTextStyle: RichTextStyle) : LeadingMarginSpan, EditorInlineSpan {
  private val leadWidth = 40
  private val gapWidth = 30

  override fun getLeadingMargin(first: Boolean): Int {
    return leadWidth + gapWidth
  }

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
    layout: Layout?
  ) {
    if (first) {
      val text = "$index."
      val width = paint.measureText(text)

      val yPosition = baseline.toFloat()
      val xPosition = (leadWidth + x - width / 2) * dir

      canvas.drawText(text, xPosition, yPosition, paint)
    }
  }

  fun getIndex(): Int {
    return index
  }

  fun setIndex(i: Int) {
    index = i
  }
}
