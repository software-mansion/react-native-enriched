package com.swmansion.enriched.common.spans

import android.graphics.Typeface
import android.text.style.StyleSpan
import com.swmansion.enriched.common.spans.interfaces.EnrichedInlineSpan
import com.swmansion.enriched.textinput.styles.HtmlStyle

@Suppress("UNUSED_PARAMETER")
class EnrichedBoldSpan(
  htmlStyle: HtmlStyle,
) : StyleSpan(Typeface.BOLD),
  EnrichedInlineSpan {
  override val dependsOnHtmlStyle: Boolean = false

  override fun rebuildWithStyle(htmlStyle: HtmlStyle): EnrichedBoldSpan = EnrichedBoldSpan(htmlStyle)
}
