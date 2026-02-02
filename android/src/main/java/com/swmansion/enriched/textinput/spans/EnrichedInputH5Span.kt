package com.swmansion.enriched.textinput.spans

import com.swmansion.enriched.common.spans.EnrichedH5Span
import com.swmansion.enriched.textinput.spans.interfaces.EnrichedInputSpan
import com.swmansion.enriched.textinput.styles.HtmlStyle

class EnrichedInputH5Span(
  htmlStyle: HtmlStyle,
) : EnrichedH5Span(htmlStyle),
  EnrichedInputSpan {
  override val dependsOnHtmlStyle: Boolean = true

  override fun rebuildWithStyle(htmlStyle: HtmlStyle): EnrichedInputH5Span = EnrichedInputH5Span(htmlStyle)
}
