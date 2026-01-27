package com.swmansion.enriched.textinput.spans

import com.swmansion.enriched.common.spans.EnrichedMentionSpan
import com.swmansion.enriched.textinput.spans.interfaces.EnrichedInputSpan
import com.swmansion.enriched.textinput.styles.HtmlStyle

class EnrichedInputMentionSpan(
  private val text: String,
  private val indicator: String,
  private val attributes: Map<String, String>,
  htmlStyle: HtmlStyle,
) : EnrichedMentionSpan(text, indicator, attributes, htmlStyle),
  EnrichedInputSpan {
  override val dependsOnHtmlStyle: Boolean = true

  override fun rebuildWithStyle(htmlStyle: HtmlStyle): EnrichedInputMentionSpan =
    EnrichedInputMentionSpan(text, indicator, attributes, htmlStyle)
}
