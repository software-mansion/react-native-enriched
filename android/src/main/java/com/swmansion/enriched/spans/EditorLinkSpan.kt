package com.swmansion.enriched.spans

import android.text.TextPaint
import android.text.style.ClickableSpan
import android.view.View
import com.swmansion.enriched.spans.interfaces.EditorInlineSpan
import com.swmansion.enriched.styles.RichTextStyle

class EditorLinkSpan(private val url: String, private val richTextStyle: RichTextStyle) : ClickableSpan(), EditorInlineSpan {
  override fun onClick(view: View) {
    // Do nothing, links inside the editor are not clickable.
    // We are using `ClickableSpan` to allow the text to be styled as a link.
  }

  override fun updateDrawState(textPaint: TextPaint) {
    super.updateDrawState(textPaint)
    textPaint.color = richTextStyle.aColor
    textPaint.isUnderlineText = richTextStyle.aUnderline
  }

  fun getUrl(): String {
    return url
  }
}
