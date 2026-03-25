package com.swmansion.enriched.textinput.utils

import android.text.SpannableStringBuilder
import com.swmansion.enriched.common.EnrichedConstants
import com.swmansion.enriched.textinput.spans.EnrichedAlignmentPlaceholderSpan

fun CharSequence.zwsCountBefore(index: Int): Int {
  var count = 0
  for (i in 0 until index) {
    if (this[i] == EnrichedConstants.ZWS) count++
  }
  return count
}

// Removes zero-width spaces from the given range in the SpannableStringBuilder without affecting spans
fun SpannableStringBuilder.removeZWS(
  start: Int,
  end: Int,
) {
  for (i in (end - 1) downTo start) {
    if (this[i] == EnrichedConstants.ZWS) {
      delete(i, i + 1)
    }
  }
}

/**
 * Removes ZWS characters in the range that are NOT anchoring an [EnrichedAlignmentPlaceholderSpan].
 * This preserves alignment placeholder ZWS while cleaning up list-related ZWS.
 */
fun SpannableStringBuilder.removeNonAlignmentZWS(
  start: Int,
  end: Int,
) {
  for (i in (end - 1) downTo start) {
    if (i >= length) continue
    if (this[i] != EnrichedConstants.ZWS) continue
    val placeholders = getSpans(i, i + 1, EnrichedAlignmentPlaceholderSpan::class.java)
    if (placeholders.isEmpty()) {
      delete(i, i + 1)
    }
  }
}
