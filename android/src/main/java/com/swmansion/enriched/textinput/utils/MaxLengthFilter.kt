package com.swmansion.enriched.textinput.utils

import android.text.InputFilter
import android.text.Spanned
import com.swmansion.enriched.common.EnrichedConstants
import com.swmansion.enriched.textinput.EnrichedTextInputView
import java.text.BreakIterator

object MaxLength {
  const val UNLIMITED = -1

  fun plainTextLengthOf(
    text: CharSequence,
    start: Int = 0,
    end: Int = text.length,
  ): Int = text.subSequence(start, end).count { it != EnrichedConstants.ZWS }

  fun cutIndexToFitWithin(
    text: CharSequence,
    start: Int,
    end: Int,
    capacity: Int,
  ): Int {
    var index = start
    var kept = 0

    while (index < end) {
      if (text[index] != EnrichedConstants.ZWS) {
        // zero width spaces are not counted, any other character needs the capacity
        if (kept >= capacity) break
        kept++
      }
      index++
    }

    return snapOutwards(text, start, end, index)
  }

  private fun snapOutwards(
    text: CharSequence,
    start: Int,
    end: Int,
    cut: Int,
  ): Int {
    if (cut <= start || cut >= end) return cut

    // here we handle potential composing characters - emojis,
    // surrogate pairs, etc. We don't want to split them in half
    val iterator = BreakIterator.getCharacterInstance()
    iterator.setText(text.subSequence(start, end).toString())

    val localCut = cut - start
    if (iterator.isBoundary(localCut)) return cut

    val prev = iterator.preceding(localCut)
    return if (prev == BreakIterator.DONE) start else start + prev
  }
}

/**
 * Applies the `maxLength` limit to every change made to the editor's text - typing, dictation, IME
 * composition, pasting and setting the value imperatively all go through the filters of the
 * underlying `Editable`.
 */
class MaxLengthFilter(
  private val view: EnrichedTextInputView,
) : InputFilter {
  override fun filter(
    source: CharSequence,
    start: Int,
    end: Int,
    dest: Spanned,
    dstart: Int,
    dend: Int,
  ): CharSequence? {
    val maxLength = view.maxLength
    if (maxLength == MaxLength.UNLIMITED) return null

    val keptLength = MaxLength.plainTextLengthOf(dest) - MaxLength.plainTextLengthOf(dest, dstart, dend)
    val capacity = maxLength - keptLength

    if (MaxLength.plainTextLengthOf(source, start, end) <= capacity) {
      // null keeps the original change
      return null
    }

    val cut = MaxLength.cutIndexToFitWithin(source, start, end, capacity)

    return if (cut <= start) "" else source.subSequence(start, cut)
  }
}
