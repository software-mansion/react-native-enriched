package com.swmansion.reactnativerichtexteditor.spans

import android.graphics.Color
import android.graphics.Typeface
import android.text.TextPaint
import android.text.style.BackgroundColorSpan
import com.swmansion.reactnativerichtexteditor.spans.interfaces.EditorInlineSpan
import com.swmansion.reactnativerichtexteditor.styles.RichTextStyle

@Suppress("UNUSED_PARAMETER")
class EditorInlineCodeSpan(private val richTextStyle: RichTextStyle) : BackgroundColorSpan(Color.argb(90, 250, 250, 250)), EditorInlineSpan {
  override fun updateDrawState(textPaint: TextPaint) {
    super.updateDrawState(textPaint)

    textPaint.color = Color.RED
    textPaint.typeface = Typeface.create(Typeface.MONOSPACE, Typeface.NORMAL)
  }
}
