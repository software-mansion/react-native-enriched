package com.swmansion.enriched.textinput.spans

import com.swmansion.enriched.common.spans.EnrichedH4Span
import com.swmansion.enriched.textinput.spans.interfaces.EnrichedInputSpan
import com.swmansion.enriched.textinput.styles.HtmlStyle

class EnrichedInputH4Span(
  htmlStyle: HtmlStyle,
) : EnrichedH4Span(htmlStyle),
  EnrichedInputSpan {
  override val dependsOnHtmlStyle: Boolean = true

  override fun rebuildWithStyle(htmlStyle: HtmlStyle): EnrichedInputH4Span = EnrichedInputH4Span(htmlStyle)
}
