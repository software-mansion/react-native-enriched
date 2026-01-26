package com.swmansion.enriched.common.spans

import android.text.style.UnderlineSpan
import com.swmansion.enriched.common.EnrichedStyle
import com.swmansion.enriched.common.spans.interfaces.EnrichedInlineSpan

@Suppress("UNUSED_PARAMETER")
open class EnrichedUnderlineSpan(
  private val enrichedStyle: EnrichedStyle,
) : UnderlineSpan(),
  EnrichedInlineSpan
