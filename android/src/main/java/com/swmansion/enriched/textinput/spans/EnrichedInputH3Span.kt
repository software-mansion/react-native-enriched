package com.swmansion.enriched.textinput.spans

import com.swmansion.enriched.common.spans.EnrichedH3Span
import com.swmansion.enriched.textinput.spans.interfaces.EnrichedInputSpan
import com.swmansion.enriched.textinput.styles.HtmlStyle

class EnrichedInputH3Span(
  htmlStyle: HtmlStyle,
) : EnrichedH3Span(htmlStyle),
  EnrichedInputSpan {
  override val dependsOnHtmlStyle: Boolean = true

  override fun rebuildWithStyle(htmlStyle: HtmlStyle): EnrichedInputH3Span = EnrichedInputH3Span(htmlStyle)
}
