package com.swmansion.enriched.textinput.spans

import com.swmansion.enriched.common.spans.EnrichedStrikeThroughSpan
import com.swmansion.enriched.textinput.spans.interfaces.EnrichedInputSpan
import com.swmansion.enriched.textinput.styles.HtmlStyle

@Suppress("UNUSED_PARAMETER")
class EnrichedInputStrikeThroughSpan(
  htmlStyle: HtmlStyle,
) : EnrichedStrikeThroughSpan(htmlStyle),
  EnrichedInputSpan {
  override val dependsOnHtmlStyle: Boolean = false

  override fun rebuildWithStyle(htmlStyle: HtmlStyle): EnrichedInputStrikeThroughSpan = EnrichedInputStrikeThroughSpan(htmlStyle)
}
