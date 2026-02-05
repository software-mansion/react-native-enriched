package com.swmansion.enriched.text.spans

import com.swmansion.enriched.common.spans.EnrichedBlockQuoteSpan
import com.swmansion.enriched.text.EnrichedTextStyle
import com.swmansion.enriched.text.spans.interfaces.EnrichedTextSpan

class EnrichedTextBlockQuoteSpan(
  enrichedStyle: EnrichedTextStyle,
) : EnrichedBlockQuoteSpan(enrichedStyle),
  EnrichedTextSpan {
  override val dependsOnHtmlStyle = true

  override fun rebuildWithStyle(style: EnrichedTextStyle) = EnrichedTextBlockQuoteSpan(style)
}
