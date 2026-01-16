package com.swmansion.enriched.textinput.spans

import com.swmansion.enriched.common.spans.EnrichedUnorderedListSpan
import com.swmansion.enriched.textinput.spans.interfaces.EnrichedInputSpan
import com.swmansion.enriched.textinput.styles.HtmlStyle

class EnrichedInputUnorderedListSpan(
  htmlStyle: HtmlStyle,
) : EnrichedUnorderedListSpan(htmlStyle),
  EnrichedInputSpan {
  override val dependsOnHtmlStyle: Boolean = true

  override fun rebuildWithStyle(htmlStyle: HtmlStyle): EnrichedInputUnorderedListSpan = EnrichedInputUnorderedListSpan(htmlStyle)
}
