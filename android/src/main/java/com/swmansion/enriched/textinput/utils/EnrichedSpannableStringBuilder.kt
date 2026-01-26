package com.swmansion.enriched.textinput.utils

import android.text.SpannableStringBuilder
import com.swmansion.enriched.common.EnrichedConstants

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
