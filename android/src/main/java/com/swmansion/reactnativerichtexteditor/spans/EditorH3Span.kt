package com.swmansion.reactnativerichtexteditor.spans

import android.graphics.Typeface
import android.text.TextPaint
import android.text.style.AbsoluteSizeSpan
import com.swmansion.reactnativerichtexteditor.spans.interfaces.EditorHeadingSpan
import com.swmansion.reactnativerichtexteditor.styles.RichTextStyle

class EditorH3Span(private val richTextStyle: RichTextStyle) : AbsoluteSizeSpan(richTextStyle.h3FontSize), EditorHeadingSpan {
  override fun updateDrawState(tp: TextPaint) {
    super.updateDrawState(tp)
    val bold = richTextStyle.h3Bold
    if (bold) {
      tp.typeface = Typeface.create(tp.typeface, Typeface.BOLD)
    }
  }
}
