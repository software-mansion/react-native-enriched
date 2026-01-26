package com.swmansion.enriched.textinput.spans

import com.swmansion.enriched.common.spans.EnrichedLinkSpan
import com.swmansion.enriched.textinput.spans.interfaces.EnrichedInputSpan
import com.swmansion.enriched.textinput.styles.HtmlStyle

class EnrichedInputLinkSpan(
  private val url: String,
  htmlStyle: HtmlStyle,
) : EnrichedLinkSpan(url, htmlStyle),
  EnrichedInputSpan {
  override val dependsOnHtmlStyle: Boolean = true

  override fun rebuildWithStyle(htmlStyle: HtmlStyle): EnrichedInputLinkSpan = EnrichedInputLinkSpan(url, htmlStyle)
}
