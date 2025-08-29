package com.swmansion.enriched.spans

import android.graphics.Typeface
import android.text.TextPaint
import android.text.style.BackgroundColorSpan
import com.swmansion.enriched.spans.interfaces.EditorInlineSpan
import com.swmansion.enriched.styles.RichTextStyle

class EditorInlineCodeSpan(private val richTextStyle: RichTextStyle) : BackgroundColorSpan(richTextStyle.inlineCodeBackgroundColor), EditorInlineSpan {
  override fun updateDrawState(textPaint: TextPaint) {
    super.updateDrawState(textPaint)

    textPaint.color = richTextStyle.inlineCodeColor
    textPaint.typeface = Typeface.create(Typeface.MONOSPACE, Typeface.NORMAL)
  }
}
