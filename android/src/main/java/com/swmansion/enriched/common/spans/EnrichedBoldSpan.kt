package com.swmansion.enriched.common.spans

import android.graphics.Typeface
import android.text.style.StyleSpan
import com.swmansion.enriched.common.EnrichedStyle
import com.swmansion.enriched.common.spans.interfaces.EnrichedInlineSpan

open class EnrichedBoldSpan(
  enrichedStyle: EnrichedStyle,
) : StyleSpan(Typeface.BOLD),
  EnrichedInlineSpan
