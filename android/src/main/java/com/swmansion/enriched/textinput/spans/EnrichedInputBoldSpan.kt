package com.swmansion.enriched.textinput.spans

import com.swmansion.enriched.common.spans.EnrichedBoldSpan
import com.swmansion.enriched.textinput.spans.interfaces.EnrichedInputSpan
import com.swmansion.enriched.textinput.styles.HtmlStyle

@Suppress("UNUSED_PARAMETER")
class EnrichedInputBoldSpan(
  htmlStyle: HtmlStyle,
) : EnrichedBoldSpan(htmlStyle),
  EnrichedInputSpan {
  override val dependsOnHtmlStyle: Boolean = false

  override fun rebuildWithStyle(htmlStyle: HtmlStyle): EnrichedInputBoldSpan = EnrichedInputBoldSpan(htmlStyle)
}
