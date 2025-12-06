package com.swmansion.enriched.spans.interfaces

import com.swmansion.enriched.styles.HtmlStyle

interface EnrichedSpan {
  fun rebuildWith(htmlStyle: HtmlStyle): EnrichedSpan
}
