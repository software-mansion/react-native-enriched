package com.swmansion.enriched.textinput.spans

import com.swmansion.enriched.common.spans.EnrichedUnderlineSpan
import com.swmansion.enriched.textinput.spans.interfaces.EnrichedInputSpan
import com.swmansion.enriched.textinput.styles.HtmlStyle

@Suppress("UNUSED_PARAMETER")
class EnrichedInputUnderlineSpan(
  htmlStyle: HtmlStyle,
) : EnrichedUnderlineSpan(htmlStyle),
  EnrichedInputSpan {
  override val dependsOnHtmlStyle: Boolean = false

  override fun rebuildWithStyle(htmlStyle: HtmlStyle): EnrichedInputUnderlineSpan = EnrichedInputUnderlineSpan(htmlStyle)
}
