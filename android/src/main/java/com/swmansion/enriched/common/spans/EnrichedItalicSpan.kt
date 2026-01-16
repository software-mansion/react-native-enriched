package com.swmansion.enriched.common.spans

import android.graphics.Typeface
import android.text.style.StyleSpan
import com.swmansion.enriched.common.EnrichedStyle
import com.swmansion.enriched.common.spans.interfaces.EnrichedInlineSpan

open class EnrichedItalicSpan(
  private val enrichedStyle: EnrichedStyle,
) : StyleSpan(Typeface.ITALIC),
  EnrichedInlineSpan
