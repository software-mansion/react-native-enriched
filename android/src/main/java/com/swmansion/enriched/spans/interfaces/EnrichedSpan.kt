package com.swmansion.enriched.spans.interfaces

import com.swmansion.enriched.styles.HtmlStyle

interface EnrichedSpan {
  val dependsOnHtmlStyle: Boolean

  fun rebuildWithStyle(htmlStyle: HtmlStyle): EnrichedSpan
}
