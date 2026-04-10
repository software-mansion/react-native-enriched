package com.swmansion.enriched.text.spans

import com.swmansion.enriched.common.EnrichedStyle
import com.swmansion.enriched.common.spans.EnrichedStrikeThroughSpan
import com.swmansion.enriched.text.EnrichedTextStyle
import com.swmansion.enriched.text.spans.interfaces.EnrichedTextSpan

class EnrichedTextStrikeThroughSpan(
  enrichedStyle: EnrichedStyle,
) : EnrichedStrikeThroughSpan(enrichedStyle),
  EnrichedTextSpan {
  override val dependsOnHtmlStyle = false

  override fun rebuildWithStyle(style: EnrichedTextStyle) = EnrichedTextStrikeThroughSpan(style)
}
