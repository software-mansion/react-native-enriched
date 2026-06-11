package com.swmansion.enriched.textinput.utils

import android.text.SpannableStringBuilder
import com.swmansion.enriched.common.EnrichedConstants
import com.swmansion.enriched.textinput.spans.EnrichedInputAlignmentSpan

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
 * Inserts a ZWS at [index] if missing, preventing duplicate anchors.
 * Returns true if inserted.
 */
fun SpannableStringBuilder.safelyInsertZWS(index: Int): Boolean {
  if (index < 0 || index > length) return false
  if (length > index && this[index] == EnrichedConstants.ZWS) return false

  insert(index, EnrichedConstants.ZWS_STRING)
  return true
}

/**
 * Removes ZWS in [start, end) only if no alignment still requires them as a layout anchor.
 */
fun SpannableStringBuilder.safelyRemoveZWS(
  start: Int,
  end: Int,
) {
  val safeStart = minOf(start, end).coerceIn(0, length)
  val safeEnd = maxOf(start, end).coerceIn(0, length)

  // return if the range is empty
  if (safeStart == safeEnd) return

  val hasAlignment = getSpans(safeStart, safeEnd, EnrichedInputAlignmentSpan::class.java).isNotEmpty()

  if (hasAlignment) return

  for (i in (safeEnd - 1) downTo safeStart) {
    if (this[i] == EnrichedConstants.ZWS) delete(i, i + 1)
  }
}
