package com.swmansion.enriched.text.spans

import com.swmansion.enriched.common.spans.EnrichedH5Span
import com.swmansion.enriched.text.EnrichedTextStyle
import com.swmansion.enriched.text.spans.interfaces.EnrichedTextSpan

class EnrichedTextH5Span(
  enrichedStyle: EnrichedTextStyle,
) : EnrichedH5Span(enrichedStyle),
  EnrichedTextSpan {
  override val dependsOnHtmlStyle = true

  override fun rebuildWithStyle(style: EnrichedTextStyle) = EnrichedTextH5Span(style)
}
