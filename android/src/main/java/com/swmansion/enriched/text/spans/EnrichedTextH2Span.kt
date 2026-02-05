package com.swmansion.enriched.text.spans

import com.swmansion.enriched.common.spans.EnrichedH2Span
import com.swmansion.enriched.text.EnrichedTextStyle
import com.swmansion.enriched.text.spans.interfaces.EnrichedTextSpan

class EnrichedTextH2Span(
  enrichedStyle: EnrichedTextStyle,
) : EnrichedH2Span(enrichedStyle),
  EnrichedTextSpan {
  override val dependsOnHtmlStyle = true

  override fun rebuildWithStyle(style: EnrichedTextStyle) = EnrichedTextH2Span(style)
}
