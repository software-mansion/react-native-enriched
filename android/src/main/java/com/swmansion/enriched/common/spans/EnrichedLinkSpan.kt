package com.swmansion.enriched.common.spans

import android.text.TextPaint
import android.text.style.ClickableSpan
import android.view.View
import com.swmansion.enriched.common.spans.interfaces.EnrichedInlineSpan
import com.swmansion.enriched.textinput.styles.HtmlStyle

class EnrichedLinkSpan(
  private val url: String,
  private val htmlStyle: HtmlStyle,
) : ClickableSpan(),
  EnrichedInlineSpan {
  override val dependsOnHtmlStyle: Boolean = true

  override fun onClick(view: View) {
    // Do nothing, links inside the input are not clickable.
    // We are using `ClickableSpan` to allow the text to be styled as a link.
  }

  override fun updateDrawState(textPaint: TextPaint) {
    super.updateDrawState(textPaint)
    textPaint.color = htmlStyle.aColor
    textPaint.isUnderlineText = htmlStyle.aUnderline
  }

  fun getUrl(): String = url

  override fun rebuildWithStyle(htmlStyle: HtmlStyle): EnrichedLinkSpan = EnrichedLinkSpan(url, htmlStyle)
}
