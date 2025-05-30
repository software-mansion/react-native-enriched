package com.swmansion.reactnativerichtexteditor.spans

import android.graphics.Color
import android.text.TextPaint
import android.text.style.ClickableSpan
import android.view.View
import com.swmansion.reactnativerichtexteditor.events.LinkHandler
import com.swmansion.reactnativerichtexteditor.spans.interfaces.EditorInlineSpan
import com.swmansion.reactnativerichtexteditor.styles.RichTextStyle

@Suppress("UNUSED_PARAMETER")
class EditorLinkSpan(private val url: String, private val linkHandler: LinkHandler, private val richTextStyle: RichTextStyle) : ClickableSpan(), EditorInlineSpan {
  override fun onClick(view: View) {
    linkHandler.onPress(url)
  }

  override fun updateDrawState(textPaint: TextPaint) {
    super.updateDrawState(textPaint)
    textPaint.color = Color.BLUE
  }

  fun getUrl(): String {
    return url
  }
}
