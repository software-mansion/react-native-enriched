package com.swmansion.reactnativerichtexteditor.spans

import android.graphics.Color
import android.text.TextPaint
import android.text.style.ClickableSpan
import android.view.View
import androidx.core.graphics.toColorInt
import com.swmansion.reactnativerichtexteditor.spans.interfaces.EditorSpan

class EditorMentionSpan(private val text: String, private val attributes: Map<String, String>) :
  ClickableSpan(), EditorSpan {
  override fun onClick(view: View) {
    // Do nothing. Mentions inside the editor are not clickable.
    // We are using `ClickableSpan` to allow the text to be styled as a clickable element.
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
