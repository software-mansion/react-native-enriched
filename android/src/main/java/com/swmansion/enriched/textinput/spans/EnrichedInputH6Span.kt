package com.swmansion.enriched.textinput.spans

import com.swmansion.enriched.common.spans.EnrichedH6Span
import com.swmansion.enriched.textinput.spans.interfaces.EnrichedInputSpan
import com.swmansion.enriched.textinput.styles.HtmlStyle

class EnrichedInputH6Span(
  htmlStyle: HtmlStyle,
) : EnrichedH6Span(htmlStyle),
  EnrichedInputSpan {
  override val dependsOnHtmlStyle: Boolean = true

  override fun rebuildWithStyle(htmlStyle: HtmlStyle): EnrichedInputH6Span = EnrichedInputH6Span(htmlStyle)
}
