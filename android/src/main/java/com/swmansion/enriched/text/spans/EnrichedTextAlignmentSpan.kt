package com.swmansion.enriched.text.spans

import com.swmansion.enriched.common.spans.EnrichedAlignmentSpan
import com.swmansion.enriched.text.EnrichedTextStyle
import com.swmansion.enriched.text.spans.interfaces.EnrichedTextSpan

class EnrichedTextAlignmentSpan(
  cssValue: String,
) : EnrichedAlignmentSpan(cssValue),
  EnrichedTextSpan {
  override val dependsOnHtmlStyle = false

  override fun rebuildWithStyle(style: EnrichedTextStyle) = this
}
