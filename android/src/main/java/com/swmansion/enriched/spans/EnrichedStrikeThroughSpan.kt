package com.swmansion.enriched.spans

import android.text.style.StrikethroughSpan
import com.swmansion.enriched.spans.interfaces.EnrichedInlineSpan
import com.swmansion.enriched.styles.HtmlStyle

@Suppress("UNUSED_PARAMETER")
class EnrichedStrikeThroughSpan(private val htmlStyle: HtmlStyle) : StrikethroughSpan(), EnrichedInlineSpan {
  override val dependsOnHtmlStyle: Boolean = false

  override fun rebuildWithStyle(htmlStyle: HtmlStyle): EnrichedStrikeThroughSpan {
    return EnrichedStrikeThroughSpan(htmlStyle)
  }
}
