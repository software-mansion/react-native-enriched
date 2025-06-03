package com.swmansion.reactnativerichtexteditor.spans

import android.graphics.Typeface
import android.text.TextPaint
import android.text.style.BackgroundColorSpan
import com.swmansion.reactnativerichtexteditor.spans.interfaces.EditorInlineSpan
import com.swmansion.reactnativerichtexteditor.styles.RichTextStyle

class EditorInlineCodeSpan(private val richTextStyle: RichTextStyle) : BackgroundColorSpan(richTextStyle.inlineCodeBackgroundColor), EditorInlineSpan {
  override fun updateDrawState(textPaint: TextPaint) {
    super.updateDrawState(textPaint)

    textPaint.color = richTextStyle.inlineCodeColor
    textPaint.typeface = Typeface.create(Typeface.MONOSPACE, Typeface.NORMAL)
  }
}
