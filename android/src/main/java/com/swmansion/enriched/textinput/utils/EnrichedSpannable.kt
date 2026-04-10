package com.swmansion.enriched.textinput.utils

import android.text.Spannable
import android.text.SpannableString
import android.text.SpannableStringBuilder
import com.swmansion.enriched.common.spans.interfaces.EnrichedBlockSpan
import com.swmansion.enriched.common.spans.interfaces.EnrichedParagraphSpan

fun Spannable.getSafeSpanBoundaries(
  start: Int,
  end: Int,
): Pair<Int, Int> {
  val safeStart = start.coerceAtMost(end).coerceAtLeast(0)
  val safeEnd = end.coerceAtLeast(start).coerceAtMost(this.length)

  return Pair(safeStart, safeEnd)
}

fun Spannable.getParagraphBounds(
  start: Int,
  end: Int,
): Pair<Int, Int> {
  var startPosition = start.coerceAtLeast(0).coerceAtMost(this.length)
  var endPosition = end.coerceAtLeast(0).coerceAtMost(this.length)

  // Find the start of the paragraph
  while (startPosition > 0 && this[startPosition - 1] != '\n') {
    startPosition--
  }

  // Find the end of the paragraph
  while (endPosition < this.length && this[endPosition] != '\n') {
    endPosition++
  }

  if (startPosition >= endPosition) {
    // If the start position is equal or greater than the end position, return the same position
    startPosition = endPosition
  }

  return Pair(startPosition, endPosition)
}

fun Spannable.getParagraphBounds(index: Int): Pair<Int, Int> = this.getParagraphBounds(index, index)

/**
 * Returns separate paragraph ranges within the given range (inclusive).
 * Mirrors iOS ParagraphsUtils.getSeparateParagraphsRangesIn:range: for alignment and list handling.
 */
fun Spannable.getParagraphRangesInRange(
  start: Int,
  end: Int,
): List<Pair<Int, Int>> {
  val (safeStart, safeEnd) = getSafeSpanBoundaries(start, end)
  if (safeStart >= length) return emptyList()

  val result = mutableListOf<Pair<Int, Int>>()
  var position = safeStart

  while (position <= safeEnd && position < length) {
    val (paragraphStart, paragraphEnd) = getParagraphBounds(position, position)
    if (paragraphStart >= safeEnd) break
    result.add(Pair(paragraphStart, paragraphEnd.coerceAtMost(length)))
    position = paragraphEnd + 1
  }

  return result
}

fun Spannable.mergeSpannables(
  start: Int,
  end: Int,
  string: String,
): Spannable = this.mergeSpannables(start, end, SpannableString(string))

fun Spannable.mergeSpannables(
  start: Int,
  end: Int,
  spannable: Spannable,
): Spannable {
  var finalStart = start
  var finalEnd = end

  val builder = SpannableStringBuilder(this)
  val startBlockSpans = spannable.getSpans(0, 0, EnrichedBlockSpan::class.java)
  val startParagraphSpans = spannable.getSpans(0, 0, EnrichedParagraphSpan::class.java)
  val endBlockSpans = spannable.getSpans(this.length, this.length, EnrichedBlockSpan::class.java)
  val endParagraphSpans = spannable.getSpans(this.length, this.length, EnrichedParagraphSpan::class.java)
  val (paragraphStart, paragraphEnd) = this.getParagraphBounds(start, end)
  val isNewLineStart = startBlockSpans.isNotEmpty() || startParagraphSpans.isNotEmpty()
  val isNewLineEnd = endBlockSpans.isNotEmpty() || endParagraphSpans.isNotEmpty()

  val pastedHasOwnStyles =
    spannable.getSpans(0, spannable.length, EnrichedBlockSpan::class.java).isNotEmpty() ||
      spannable.getSpans(0, spannable.length, EnrichedParagraphSpan::class.java).isNotEmpty()

  if (isNewLineStart && start != paragraphStart) {
    builder.insert(start, "\n")
    finalStart = start + 1
    finalEnd = end + 1
  }

  if (isNewLineEnd && end != paragraphEnd) {
    builder.insert(finalEnd, "\n")
  }

  builder.replace(finalStart, finalEnd, spannable)

  // Manually extend existing paragraph/block spans to cover the pasted text.
  if (!pastedHasOwnStyles) {
    val pasteEnd = finalStart + spannable.length

    val affectedParagraphSpans = builder.getSpans(finalStart, finalStart, EnrichedParagraphSpan::class.java)
    val affectedBlockSpans = builder.getSpans(finalStart, finalStart, EnrichedBlockSpan::class.java)
    val affectedSpans = affectedBlockSpans.toList() + affectedParagraphSpans.toList()

    for (span in affectedSpans) {
      val spanStart = builder.getSpanStart(span)
      val spanEnd = builder.getSpanEnd(span)
      if (spanStart == -1 || spanEnd >= pasteEnd) continue

      val (_, newParagraphEnd) = builder.getParagraphBounds(spanStart, pasteEnd)
      val flags = builder.getSpanFlags(span)
      builder.removeSpan(span)
      builder.setSpan(span, spanStart, newParagraphEnd, flags)
    }
  }

  return builder
}
