package com.swmansion.enriched.common.spans.interfaces

import com.swmansion.enriched.textinput.styles.HtmlStyle

interface EnrichedSpan {
  val dependsOnHtmlStyle: Boolean

  fun rebuildWithStyle(htmlStyle: HtmlStyle): EnrichedSpan
}
