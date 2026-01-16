package com.swmansion.enriched.textinput.spans.interfaces

import com.swmansion.enriched.common.spans.interfaces.EnrichedSpan
import com.swmansion.enriched.textinput.styles.HtmlStyle

interface EnrichedInputSpan : EnrichedSpan {
  val dependsOnHtmlStyle: Boolean

  fun rebuildWithStyle(htmlStyle: HtmlStyle): EnrichedSpan
}
