package com.swmansion.reactnativerichtexteditor.spans

import android.graphics.Canvas
import android.graphics.Paint
import android.text.Layout
import android.text.style.LeadingMarginSpan
import com.swmansion.reactnativerichtexteditor.spans.interfaces.EditorParagraphSpan
import com.swmansion.reactnativerichtexteditor.styles.RichTextStyle

class EditorOrderedListSpan(private var index: Int, private val richTextStyle: RichTextStyle) : LeadingMarginSpan, EditorParagraphSpan {
  override fun getLeadingMargin(first: Boolean): Int {
    return richTextStyle.olMarginLeft + richTextStyle.olGapWidth
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
      val xPosition = (richTextStyle.olMarginLeft + x - width / 2) * dir

      val originalColor = paint.color
      paint.color = richTextStyle.olMarkerColor ?: originalColor
      canvas.drawText(text, xPosition, yPosition, paint)
      paint.color = originalColor
    }
  }

  fun getIndex(): Int {
    return index
  }

  fun setIndex(i: Int) {
    index = i
  }
}
