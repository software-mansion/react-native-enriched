package com.swmansion.enriched.text.spans.interfaces

import com.swmansion.enriched.common.spans.interfaces.EnrichedSpan
import com.swmansion.enriched.text.EnrichedTextStyle

interface EnrichedTextSpan : EnrichedSpan {
  val dependsOnHtmlStyle: Boolean

  fun rebuildWithStyle(style: EnrichedTextStyle): EnrichedTextSpan
}
