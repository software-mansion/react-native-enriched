package com.swmansion.reactnativerichtexteditor.spans

import android.graphics.Color
import android.text.TextPaint
import android.text.style.ClickableSpan
import android.view.View
import com.swmansion.reactnativerichtexteditor.spans.interfaces.EditorSpan


class EditorLinkSpan(private val url: String) : ClickableSpan(), EditorSpan {
  override fun onClick(view: View) {
    // Do nothing, links inside the editor are not clickable.
    // We are using `ClickableSpan` to allow the text to be styled as a link.
  }

  override fun updateDrawState(textPaint: TextPaint) {
    super.updateDrawState(textPaint)
    textPaint.color = Color.BLUE
  }

  fun getUrl(): String {
    return url
  }
}
