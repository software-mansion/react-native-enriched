package com.swmansion.enriched.textinput.spans

import com.swmansion.enriched.common.spans.EnrichedInlineCodeSpan
import com.swmansion.enriched.textinput.spans.interfaces.EnrichedInputSpan
import com.swmansion.enriched.textinput.styles.HtmlStyle

class EnrichedInputInlineCodeSpan(
  htmlStyle: HtmlStyle,
) : EnrichedInlineCodeSpan(htmlStyle),
  EnrichedInputSpan {
  override val dependsOnHtmlStyle: Boolean = true

  override fun rebuildWithStyle(htmlStyle: HtmlStyle): EnrichedInputInlineCodeSpan = EnrichedInputInlineCodeSpan(htmlStyle)
}
