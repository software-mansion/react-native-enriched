package com.swmansion.enriched.text.spans

import com.swmansion.enriched.common.spans.EnrichedBoldSpan
import com.swmansion.enriched.text.EnrichedTextStyle
import com.swmansion.enriched.text.spans.interfaces.EnrichedTextSpan

class EnrichedTextBoldSpan(
  enrichedStyle: EnrichedTextStyle,
) : EnrichedBoldSpan(enrichedStyle),
  EnrichedTextSpan {
  override val dependsOnHtmlStyle = false

  override fun rebuildWithStyle(style: EnrichedTextStyle) = EnrichedTextBoldSpan(style)
}
