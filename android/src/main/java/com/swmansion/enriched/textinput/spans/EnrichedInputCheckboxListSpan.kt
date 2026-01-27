package com.swmansion.enriched.textinput.spans

import com.swmansion.enriched.common.spans.EnrichedCheckboxListSpan
import com.swmansion.enriched.textinput.spans.interfaces.EnrichedInputSpan
import com.swmansion.enriched.textinput.styles.HtmlStyle

class EnrichedInputCheckboxListSpan(
  override var isChecked: Boolean,
  htmlStyle: HtmlStyle,
) : EnrichedCheckboxListSpan(isChecked, htmlStyle),
  EnrichedInputSpan {
  override val dependsOnHtmlStyle: Boolean = true

  override fun rebuildWithStyle(htmlStyle: HtmlStyle): EnrichedInputCheckboxListSpan = EnrichedInputCheckboxListSpan(isChecked, htmlStyle)
}
