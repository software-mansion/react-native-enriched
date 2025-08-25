package com.swmansion.reactnativerichtexteditor.spans

import android.graphics.Typeface
import android.text.TextPaint
import android.text.style.AbsoluteSizeSpan
import com.swmansion.reactnativerichtexteditor.spans.interfaces.EditorHeadingSpan
import com.swmansion.reactnativerichtexteditor.styles.RichTextStyle

class EditorH1Span(private val style: RichTextStyle) : AbsoluteSizeSpan(style.h1FontSize), EditorHeadingSpan {
  override fun updateDrawState(tp: TextPaint) {
    super.updateDrawState(tp)
    val bold = style.h1Bold
    if (bold) {
      tp.typeface = Typeface.create(tp.typeface, Typeface.BOLD)
    }
  }
}
