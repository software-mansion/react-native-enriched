package com.swmansion.reactnativerichtexteditor.spans

import android.graphics.Color
import android.text.TextPaint
import android.text.style.ClickableSpan
import android.view.View
import com.swmansion.reactnativerichtexteditor.events.LinkHandler
import com.swmansion.reactnativerichtexteditor.spans.interfaces.EditorSpan


class EditorLinkSpan(private val url: String, private val linkHandler: LinkHandler) : ClickableSpan(), EditorSpan {
  override fun onClick(widget: View) {
    linkHandler.onClick(url)
  }

  override fun updateDrawState(textPaint: TextPaint) {
    super.updateDrawState(textPaint)
    textPaint.color = Color.BLUE
  }

  fun getUrl(): String {
    return url
  }
}
