package com.swmansion.enriched.textinput.spans

import com.swmansion.enriched.common.spans.EnrichedCodeBlockSpan
import com.swmansion.enriched.textinput.spans.interfaces.EnrichedInputSpan
import com.swmansion.enriched.textinput.styles.HtmlStyle

class EnrichedInputCodeBlockSpan(
  htmlStyle: HtmlStyle,
) : EnrichedCodeBlockSpan(htmlStyle),
  EnrichedInputSpan {
  override val dependsOnHtmlStyle: Boolean = true

  override fun rebuildWithStyle(htmlStyle: HtmlStyle): EnrichedInputCodeBlockSpan = EnrichedInputCodeBlockSpan(htmlStyle)
}
