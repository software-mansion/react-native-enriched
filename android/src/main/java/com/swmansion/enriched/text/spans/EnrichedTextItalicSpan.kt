package com.swmansion.enriched.text.spans

import com.swmansion.enriched.common.spans.EnrichedItalicSpan
import com.swmansion.enriched.text.EnrichedTextStyle
import com.swmansion.enriched.text.spans.interfaces.EnrichedTextSpan

class EnrichedTextItalicSpan(
  enrichedStyle: EnrichedTextStyle,
) : EnrichedItalicSpan(enrichedStyle),
  EnrichedTextSpan {
  override val dependsOnHtmlStyle = false

  override fun rebuildWithStyle(style: EnrichedTextStyle) = EnrichedTextItalicSpan(style)
}
