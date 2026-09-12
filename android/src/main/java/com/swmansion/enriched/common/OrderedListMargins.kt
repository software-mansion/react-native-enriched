package com.swmansion.enriched.common

import android.graphics.Paint
import android.text.Spannable
import com.swmansion.enriched.common.spans.EnrichedOrderedListSpan
import com.swmansion.enriched.textinput.utils.getSafeSpanBoundaries

// Recomputes the shared marker column width for every ordered-list item.
fun updateOrderedListColumnMargins(
  text: Spannable,
  paint: Paint,
) {
  val spans = text.getSpans(0, text.length, EnrichedOrderedListSpan::class.java)
  val sortedSpans = spans.sortedBy { text.getSpanStart(it) }

  val changedLists = mutableSetOf<MutableList<EnrichedOrderedListSpan>>()
  var currentList = mutableListOf<EnrichedOrderedListSpan>()
  var currentListChanged = false
  var previousIndex = 0
  var highestIndex = 0

  for (span in sortedSpans.reversed()) {
    if (span.index >= previousIndex) {
      if (currentListChanged) {
        // we'll re-layout that list
        changedLists.add(currentList)
      }

      // we entered a new distinct list
      currentList = mutableListOf()
      currentListChanged = false
      highestIndex = span.index
    }

    currentList.add(span)
    if (span.updateColumnMargin(paint, highestIndex)) {
      currentListChanged = true
    }

    previousIndex = span.index
  }

  if (currentListChanged) {
    changedLists.add(currentList)
  }

  // A single empty ParagraphStyle over the whole list forces one re-layout of it.
  // Uses the same trick as EnrichedSpanWatcher.updateNextLineLayout.
  for (list in changedLists) {
    forceOrderedListRelayout(text, list)
  }
}

private fun forceOrderedListRelayout(
  text: Spannable,
  listSpans: List<EnrichedOrderedListSpan>,
) {
  if (listSpans.isEmpty()) return

  // Because the list was populated during a reversed() loop, the elements
  // are in descending order. last() is the start of the list, first() is the end.
  val start = text.getSpanStart(listSpans.last())
  val end = text.getSpanEnd(listSpans.first())

  if (start < 0 || end < 0 || start > end) return

  val (safeStart, safeEnd) = text.getSafeSpanBoundaries(start, end)
  text.getSpans(safeStart, safeEnd, EmptyParagraphSpan::class.java).forEach { text.removeSpan(it) }
  text.setSpan(EmptyParagraphSpan(), safeStart, safeEnd, Spannable.SPAN_EXCLUSIVE_EXCLUSIVE)
}
