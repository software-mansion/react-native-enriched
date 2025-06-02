package com.swmansion.reactnativerichtexteditor.spans

import android.graphics.Canvas
import android.graphics.Paint
import android.text.Layout
import android.text.Spanned
import android.text.style.LeadingMarginSpan
import com.swmansion.reactnativerichtexteditor.spans.interfaces.EditorInlineSpan
import com.swmansion.reactnativerichtexteditor.styles.RichTextStyle

// https://android.googlesource.com/platform/frameworks/base/+/refs/heads/main/core/java/android/text/style/BulletSpan.java
class EditorUnorderedListSpan(private val richTextStyle: RichTextStyle) : LeadingMarginSpan, EditorInlineSpan {
  override fun getLeadingMargin(p0: Boolean): Int {
    return richTextStyle.ulBulletSize + richTextStyle.ulGapWidth
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
      var oldColor = paint.color
      paint.color = richTextStyle.ulBulletColor
      paint.style = Paint.Style.FILL

      val bulletRadius = richTextStyle.ulBulletSize / 2f
      val yPosition = (top + bottom) / 2f
      val xPosition = x + dir * bulletRadius + richTextStyle.ulMarginLeft

      canvas.drawCircle(xPosition.toFloat(), yPosition, bulletRadius, paint)

      paint.color = oldColor
      paint.style = style
    }
  }
}
