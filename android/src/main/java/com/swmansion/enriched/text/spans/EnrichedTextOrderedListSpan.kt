package com.swmansion.enriched.text.spans

import com.swmansion.enriched.common.EnrichedStyle
import com.swmansion.enriched.common.spans.EnrichedOrderedListSpan
import com.swmansion.enriched.text.EnrichedTextStyle
import com.swmansion.enriched.text.spans.interfaces.EnrichedTextSpan

class EnrichedTextOrderedListSpan(
  private val index: Int,
  enrichedStyle: EnrichedStyle,
) : EnrichedOrderedListSpan(index, enrichedStyle),
  EnrichedTextSpan {
  override val dependsOnHtmlStyle = true

  override fun rebuildWithStyle(style: EnrichedTextStyle) = EnrichedTextOrderedListSpan(index, style)
}
