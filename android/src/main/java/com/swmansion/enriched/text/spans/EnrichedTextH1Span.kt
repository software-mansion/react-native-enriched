package com.swmansion.enriched.text.spans

import com.swmansion.enriched.common.spans.EnrichedH1Span
import com.swmansion.enriched.text.EnrichedTextStyle
import com.swmansion.enriched.text.spans.interfaces.EnrichedTextSpan

class EnrichedTextH1Span(
  enrichedStyle: EnrichedTextStyle,
) : EnrichedH1Span(enrichedStyle),
  EnrichedTextSpan {
  override val dependsOnHtmlStyle = true

  override fun rebuildWithStyle(style: EnrichedTextStyle) = EnrichedTextH1Span(style)
}
