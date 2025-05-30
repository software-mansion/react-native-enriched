package com.swmansion.reactnativerichtexteditor.spans

import android.graphics.Color
import android.text.TextPaint
import android.text.style.ClickableSpan
import android.view.View
import androidx.core.graphics.toColorInt
import com.swmansion.reactnativerichtexteditor.events.MentionHandler
import com.swmansion.reactnativerichtexteditor.spans.interfaces.EditorInlineSpan

class EditorMentionSpan(private val text: String, private val attributes: Map<String, String>, private val mentionHandler: MentionHandler) :
  ClickableSpan(), EditorInlineSpan {
  override fun onClick(view: View) {
    mentionHandler.onPress(text, attributes)
  }

  override fun updateDrawState(textPaint: TextPaint) {
    super.updateDrawState(textPaint)

    textPaint.color = Color.BLUE
    textPaint.bgColor = "#33088F8F".toColorInt()
  }

  fun getAttributes(): Map<String, String> {
    return attributes
  }

  fun getText(): String {
    return text
  }
}
