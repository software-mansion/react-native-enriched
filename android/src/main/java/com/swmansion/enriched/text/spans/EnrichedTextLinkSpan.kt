package com.swmansion.enriched.text.spans

import com.swmansion.enriched.common.spans.EnrichedLinkSpan
import com.swmansion.enriched.text.EnrichedTextStyle
import com.swmansion.enriched.text.spans.interfaces.EnrichedTextSpan

class EnrichedTextLinkSpan(
  private val url: String,
  enrichedStyle: EnrichedTextStyle,
) : EnrichedLinkSpan(url, enrichedStyle),
  EnrichedTextSpan {
  override val dependsOnHtmlStyle = true

  override fun rebuildWithStyle(style: EnrichedTextStyle) = EnrichedTextLinkSpan(url, style)
}
