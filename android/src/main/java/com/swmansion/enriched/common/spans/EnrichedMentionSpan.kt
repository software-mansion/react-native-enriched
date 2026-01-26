package com.swmansion.enriched.common.spans

import android.text.TextPaint
import android.text.style.ClickableSpan
import android.view.View
import com.swmansion.enriched.common.EnrichedStyle
import com.swmansion.enriched.common.spans.interfaces.EnrichedInlineSpan

open class EnrichedMentionSpan(
  private val text: String,
  private val indicator: String,
  private val attributes: Map<String, String>,
  private val enrichedStyle: EnrichedStyle,
) : ClickableSpan(),
  EnrichedInlineSpan {
  override fun onClick(view: View) {
    // Do nothing. Mentions inside the input are not clickable.
    // We are using `ClickableSpan` to allow the text to be styled as a clickable element.
  }

  override fun updateDrawState(textPaint: TextPaint) {
    super.updateDrawState(textPaint)

    val mentionsStyle = enrichedStyle.mentionsStyle[indicator] ?: return
    textPaint.color = mentionsStyle.color
    textPaint.bgColor = mentionsStyle.backgroundColor
    textPaint.isUnderlineText = mentionsStyle.underline
  }

  fun getAttributes(): Map<String, String> = attributes

  fun getText(): String = text

  fun getIndicator(): String = indicator
}
