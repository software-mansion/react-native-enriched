package com.swmansion.enriched.text.spans

import com.swmansion.enriched.common.spans.EnrichedInlineCodeSpan
import com.swmansion.enriched.text.EnrichedTextStyle
import com.swmansion.enriched.text.spans.interfaces.EnrichedTextSpan

class EnrichedTextInlineCodeSpan(
  enrichedStyle: EnrichedTextStyle,
) : EnrichedInlineCodeSpan(enrichedStyle),
  EnrichedTextSpan {
  override val dependsOnHtmlStyle = true

  override fun rebuildWithStyle(style: EnrichedTextStyle) = EnrichedTextInlineCodeSpan(style)
}
