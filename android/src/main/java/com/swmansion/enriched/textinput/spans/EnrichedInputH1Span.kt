package com.swmansion.enriched.textinput.spans

import com.swmansion.enriched.common.spans.EnrichedH1Span
import com.swmansion.enriched.textinput.spans.interfaces.EnrichedInputSpan
import com.swmansion.enriched.textinput.styles.HtmlStyle

class EnrichedInputH1Span(
  style: HtmlStyle,
) : EnrichedH1Span(style),
  EnrichedInputSpan {
  override val dependsOnHtmlStyle: Boolean = true

  override fun rebuildWithStyle(htmlStyle: HtmlStyle): EnrichedInputH1Span = EnrichedInputH1Span(htmlStyle)
}
