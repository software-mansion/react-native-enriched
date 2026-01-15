package com.swmansion.enriched.textinput.spans

import android.text.style.UnderlineSpan
import com.swmansion.enriched.textinput.spans.interfaces.EnrichedInlineSpan
import com.swmansion.enriched.textinput.styles.HtmlStyle

@Suppress("UNUSED_PARAMETER")
class EnrichedUnderlineSpan(
  private val htmlStyle: HtmlStyle,
) : UnderlineSpan(),
  EnrichedInlineSpan {
  override val dependsOnHtmlStyle: Boolean = false

  override fun rebuildWithStyle(htmlStyle: HtmlStyle): EnrichedUnderlineSpan = EnrichedUnderlineSpan(htmlStyle)
}
