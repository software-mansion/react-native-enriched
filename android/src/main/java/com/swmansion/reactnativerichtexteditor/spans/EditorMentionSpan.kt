package com.swmansion.reactnativerichtexteditor.spans

import android.graphics.Color
import android.text.TextPaint
import android.text.style.ClickableSpan
import android.view.View
import androidx.core.graphics.toColorInt
import com.swmansion.reactnativerichtexteditor.events.MentionHandler
import com.swmansion.reactnativerichtexteditor.spans.interfaces.EditorSpan

class EditorMentionSpan(private val value: String, private val text: String, private val mentionHandler: MentionHandler) :
  ClickableSpan(), EditorSpan {
  override fun onClick(view: View) {
    mentionHandler.onPress(text, value)
  }

  override fun updateDrawState(textPaint: TextPaint) {
    super.updateDrawState(textPaint)

    textPaint.color = Color.BLUE
    textPaint.bgColor = "#33088F8F".toColorInt()
  }

  fun getValue(): String {
    return value
  }

  fun getText(): String {
    return text
  }
}
