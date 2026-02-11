package com.swmansion.enriched.text.spans

import com.swmansion.enriched.common.spans.EnrichedCodeBlockSpan
import com.swmansion.enriched.text.EnrichedTextStyle
import com.swmansion.enriched.text.spans.interfaces.EnrichedTextSpan

class EnrichedTextCodeBlockSpan(
  enrichedStyle: EnrichedTextStyle,
) : EnrichedCodeBlockSpan(enrichedStyle),
  EnrichedTextSpan {
  override val dependsOnHtmlStyle = true

  override fun rebuildWithStyle(style: EnrichedTextStyle) = EnrichedTextCodeBlockSpan(style)
}
