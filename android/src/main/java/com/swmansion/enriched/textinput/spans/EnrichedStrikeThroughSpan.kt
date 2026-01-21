package com.swmansion.enriched.textinput.spans

import android.text.style.StrikethroughSpan
import com.swmansion.enriched.textinput.spans.interfaces.EnrichedInlineSpan
import com.swmansion.enriched.textinput.styles.HtmlStyle

@Suppress("UNUSED_PARAMETER")
class EnrichedStrikeThroughSpan(
  private val htmlStyle: HtmlStyle,
) : StrikethroughSpan(),
  EnrichedInlineSpan {
  override val dependsOnHtmlStyle: Boolean = false

  override fun rebuildWithStyle(htmlStyle: HtmlStyle): EnrichedStrikeThroughSpan = EnrichedStrikeThroughSpan(htmlStyle)
}
