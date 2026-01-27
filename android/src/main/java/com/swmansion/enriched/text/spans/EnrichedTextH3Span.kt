package com.swmansion.enriched.text.spans

import com.swmansion.enriched.common.EnrichedStyle
import com.swmansion.enriched.common.spans.EnrichedH3Span
import com.swmansion.enriched.text.EnrichedTextStyle
import com.swmansion.enriched.text.spans.interfaces.EnrichedTextSpan

class EnrichedTextH3Span(
  enrichedStyle: EnrichedStyle,
) : EnrichedH3Span(enrichedStyle),
  EnrichedTextSpan {
  override val dependsOnHtmlStyle = true

  override fun rebuildWithStyle(style: EnrichedTextStyle) = EnrichedTextH3Span(style)
}
