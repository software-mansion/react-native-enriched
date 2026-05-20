package com.swmansion.enriched.textinput.spans

import com.swmansion.enriched.common.spans.EnrichedAlignmentSpan
import com.swmansion.enriched.textinput.spans.interfaces.EnrichedInputSpan
import com.swmansion.enriched.textinput.styles.HtmlStyle

class EnrichedInputAlignmentSpan(
  cssValue: String,
) : EnrichedAlignmentSpan(cssValue),
  EnrichedInputSpan {
  override val dependsOnHtmlStyle: Boolean = false

  override fun rebuildWithStyle(htmlStyle: HtmlStyle): EnrichedInputAlignmentSpan = this
}
