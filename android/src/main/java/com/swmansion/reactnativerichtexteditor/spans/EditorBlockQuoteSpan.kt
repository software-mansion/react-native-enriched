package com.swmansion.reactnativerichtexteditor.spans

import android.graphics.Canvas
import android.graphics.Color
import android.graphics.Paint
import android.text.Layout
import android.text.style.LeadingMarginSpan
import com.swmansion.reactnativerichtexteditor.spans.interfaces.EditorParagraphSpan
import com.swmansion.reactnativerichtexteditor.styles.RichTextStyle

// https://android.googlesource.com/platform/frameworks/base/+/refs/heads/main/core/java/android/text/style/QuoteSpan.java
@Suppress("UNUSED_PARAMETER")
class EditorBlockQuoteSpan(private val richTextStyle: RichTextStyle) : LeadingMarginSpan, EditorParagraphSpan {
  private val mColor = Color.CYAN
  private val mStripeWidth = 8
  private val mGapWidth = 24

  override fun getLeadingMargin(p0: Boolean): Int {
    return mStripeWidth + mGapWidth
  }

  override fun drawLeadingMargin(c: Canvas, p: Paint, x: Int, dir: Int, top: Int, baseline: Int, bottom: Int, text: CharSequence?, start: Int, end: Int, first: Boolean, layout: Layout?) {
    val style = p.style
    val color = p.color
    p.style = Paint.Style.FILL
    p.color = mColor
    c.drawRect(x.toFloat(), top.toFloat(), x + dir * mStripeWidth.toFloat(), bottom.toFloat(), p)
    p.style = style
    p.color = color
  }
}
