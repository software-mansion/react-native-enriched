package com.swmansion.enriched.text.spans

import com.swmansion.enriched.common.EnrichedStyle
import com.swmansion.enriched.common.spans.EnrichedMentionSpan
import com.swmansion.enriched.text.EnrichedTextStyle
import com.swmansion.enriched.text.spans.interfaces.EnrichedTextSpan

class EnrichedTextMentionSpan(
  private val text: String,
  private val indicator: String,
  private val attributes: Map<String, String>,
  enrichedStyle: EnrichedStyle,
) : EnrichedMentionSpan(text, indicator, attributes, enrichedStyle),
  EnrichedTextSpan {
  override val dependsOnHtmlStyle = true

  override fun rebuildWithStyle(style: EnrichedTextStyle) = EnrichedTextMentionSpan(text, indicator, attributes, style)
}
