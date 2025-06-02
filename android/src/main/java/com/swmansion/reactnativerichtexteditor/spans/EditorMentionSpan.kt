package com.swmansion.reactnativerichtexteditor.spans

import android.text.TextPaint
import android.text.style.ClickableSpan
import android.view.View
import com.swmansion.reactnativerichtexteditor.events.MentionHandler
import com.swmansion.reactnativerichtexteditor.spans.interfaces.EditorInlineSpan
import com.swmansion.reactnativerichtexteditor.styles.RichTextStyle

class EditorMentionSpan(private val text: String, private val attributes: Map<String, String>, private val mentionHandler: MentionHandler, private val richTextStyle: RichTextStyle) :
  ClickableSpan(), EditorInlineSpan {
  override fun onClick(view: View) {
    mentionHandler.onPress(text, attributes)
  }

  override fun updateDrawState(textPaint: TextPaint) {
    super.updateDrawState(textPaint)

    textPaint.color = richTextStyle.mentionColor
    textPaint.bgColor = richTextStyle.mentionBackgroundColor
    textPaint.isUnderlineText = richTextStyle.mentionUnderline
  }

  fun getAttributes(): Map<String, String> {
    return attributes
  }

  fun getText(): String {
    return text
  }
}
