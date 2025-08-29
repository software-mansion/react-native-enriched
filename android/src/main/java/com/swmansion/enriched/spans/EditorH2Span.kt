package com.swmansion.enriched.spans

import android.graphics.Typeface
import android.text.TextPaint
import android.text.style.AbsoluteSizeSpan
import com.swmansion.enriched.spans.interfaces.EditorHeadingSpan
import com.swmansion.enriched.styles.RichTextStyle

class EditorH2Span(private val richTextStyle: RichTextStyle) : AbsoluteSizeSpan(richTextStyle.h2FontSize), EditorHeadingSpan {
  override fun updateDrawState(tp: TextPaint) {
    super.updateDrawState(tp)
    val bold = richTextStyle.h2Bold
    if (bold) {
      tp.typeface = Typeface.create(tp.typeface, Typeface.BOLD)
    }
  }
}
