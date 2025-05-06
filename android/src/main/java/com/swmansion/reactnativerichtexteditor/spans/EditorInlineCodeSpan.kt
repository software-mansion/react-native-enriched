package com.swmansion.reactnativerichtexteditor.spans

import android.graphics.Color
import android.graphics.Typeface
import android.text.TextPaint
import android.text.style.BackgroundColorSpan
import com.swmansion.reactnativerichtexteditor.spans.interfaces.EditorSpan

class EditorInlineCodeSpan : BackgroundColorSpan(Color.argb(90, 250, 250, 250)), EditorSpan {
  override fun updateDrawState(textPaint: TextPaint) {
    super.updateDrawState(textPaint)

    textPaint.color = Color.RED
    textPaint.typeface = Typeface.create(Typeface.MONOSPACE, Typeface.NORMAL)
  }
}
