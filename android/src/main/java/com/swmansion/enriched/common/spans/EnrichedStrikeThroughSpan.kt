package com.swmansion.enriched.common.spans

import android.text.style.StrikethroughSpan
import com.swmansion.enriched.common.EnrichedStyle
import com.swmansion.enriched.common.spans.interfaces.EnrichedInlineSpan

@Suppress("UNUSED_PARAMETER")
open class EnrichedStrikeThroughSpan(
  enrichedStyle: EnrichedStyle,
) : StrikethroughSpan(),
  EnrichedInlineSpan
