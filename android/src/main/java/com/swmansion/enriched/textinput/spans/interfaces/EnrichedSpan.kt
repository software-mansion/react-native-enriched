package com.swmansion.enriched.textinput.spans.interfaces

import com.swmansion.enriched.textinput.styles.HtmlStyle

interface EnrichedSpan {
  val dependsOnHtmlStyle: Boolean

  fun rebuildWithStyle(htmlStyle: HtmlStyle): EnrichedSpan
}
