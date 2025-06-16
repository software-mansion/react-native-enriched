package com.swmansion.reactnativerichtexteditor.spans

import android.graphics.Canvas
import android.graphics.Paint
import android.text.Layout
import android.text.style.LeadingMarginSpan
import com.swmansion.reactnativerichtexteditor.spans.interfaces.EditorBlockSpan
import com.swmansion.reactnativerichtexteditor.styles.RichTextStyle

// https://android.googlesource.com/platform/frameworks/base/+/refs/heads/main/core/java/android/text/style/QuoteSpan.java
class EditorBlockQuoteSpan(private val richTextStyle: RichTextStyle) : LeadingMarginSpan, EditorBlockSpan {
  override fun getLeadingMargin(p0: Boolean): Int {
    return richTextStyle.blockquoteStripeWidth + richTextStyle.blockquoteGapWidth
  }

  override fun drawLeadingMargin(c: Canvas, p: Paint, x: Int, dir: Int, top: Int, baseline: Int, bottom: Int, text: CharSequence?, start: Int, end: Int, first: Boolean, layout: Layout?) {
    val style = p.style
    val color = p.color
    p.style = Paint.Style.FILL
    p.color = richTextStyle.blockquoteColor
    c.drawRect(x.toFloat(), top.toFloat(), x + dir * richTextStyle.blockquoteStripeWidth.toFloat(), bottom.toFloat(), p)
    p.style = style
    p.color = color
  }
}
