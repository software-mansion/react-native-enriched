package com.swmansion.enriched.textinput.spans

import com.swmansion.enriched.common.spans.EnrichedH2Span
import com.swmansion.enriched.textinput.spans.interfaces.EnrichedInputSpan
import com.swmansion.enriched.textinput.styles.HtmlStyle

class EnrichedInputH2Span(
  htmlStyle: HtmlStyle,
) : EnrichedH2Span(htmlStyle),
  EnrichedInputSpan {
  override val dependsOnHtmlStyle: Boolean = true

  override fun rebuildWithStyle(htmlStyle: HtmlStyle): EnrichedInputH2Span = EnrichedInputH2Span(htmlStyle)
}
