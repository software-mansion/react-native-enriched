package com.swmansion.enriched.spans

import android.text.style.UnderlineSpan
import com.swmansion.enriched.spans.interfaces.EnrichedInlineSpan
import com.swmansion.enriched.styles.HtmlStyle

@Suppress("UNUSED_PARAMETER")
class EnrichedUnderlineSpan(private val htmlStyle: HtmlStyle) : UnderlineSpan(), EnrichedInlineSpan {
}
