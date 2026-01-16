package com.swmansion.enriched.textinput.spans

import com.swmansion.enriched.common.spans.EnrichedBlockQuoteSpan
import com.swmansion.enriched.textinput.spans.interfaces.EnrichedInputSpan
import com.swmansion.enriched.textinput.styles.HtmlStyle

// https://android.googlesource.com/platform/frameworks/base/+/refs/heads/main/core/java/android/text/style/QuoteSpan.java
class EnrichedInputBlockQuoteSpan(
  htmlStyle: HtmlStyle,
) : EnrichedBlockQuoteSpan(htmlStyle),
  EnrichedInputSpan {
  override val dependsOnHtmlStyle: Boolean = true

  override fun rebuildWithStyle(htmlStyle: HtmlStyle): EnrichedInputBlockQuoteSpan = EnrichedInputBlockQuoteSpan(htmlStyle)
}
