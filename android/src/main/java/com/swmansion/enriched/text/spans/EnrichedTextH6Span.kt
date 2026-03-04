package com.swmansion.enriched.text.spans

import com.swmansion.enriched.common.spans.EnrichedH6Span
import com.swmansion.enriched.text.EnrichedTextStyle
import com.swmansion.enriched.text.spans.interfaces.EnrichedTextSpan

class EnrichedTextH6Span(
  enrichedStyle: EnrichedTextStyle,
) : EnrichedH6Span(enrichedStyle),
  EnrichedTextSpan {
  override val dependsOnHtmlStyle = true

  override fun rebuildWithStyle(style: EnrichedTextStyle) = EnrichedTextH6Span(style)
}
