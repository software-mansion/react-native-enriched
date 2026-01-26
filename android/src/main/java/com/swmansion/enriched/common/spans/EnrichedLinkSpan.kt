package com.swmansion.enriched.common.spans

import android.text.TextPaint
import android.text.style.ClickableSpan
import android.view.View
import com.swmansion.enriched.common.EnrichedStyle
import com.swmansion.enriched.common.spans.interfaces.EnrichedInlineSpan

open class EnrichedLinkSpan(
  private val url: String,
  private val enrichedStyle: EnrichedStyle,
) : ClickableSpan(),
  EnrichedInlineSpan {
  override fun onClick(view: View) {
    // Do nothing, links inside the input are not clickable.
    // We are using `ClickableSpan` to allow the text to be styled as a link.
  }

  override fun updateDrawState(textPaint: TextPaint) {
    super.updateDrawState(textPaint)
    textPaint.color = enrichedStyle.aColor
    textPaint.isUnderlineText = enrichedStyle.aUnderline
  }

  fun getUrl(): String = url
}
