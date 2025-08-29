package com.swmansion.enriched.spans

import android.graphics.Typeface
import android.text.style.StyleSpan
import com.swmansion.enriched.spans.interfaces.EnrichedInlineSpan
import com.swmansion.enriched.styles.HtmlStyle

@Suppress("UNUSED_PARAMETER")
class EnrichedBoldSpan(htmlStyle: HtmlStyle) : StyleSpan(Typeface.BOLD), EnrichedInlineSpan {
}
