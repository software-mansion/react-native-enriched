package com.swmansion.enriched.textinput.styles

import android.text.Editable
import android.text.Layout
import android.text.Spannable
import android.text.SpannableStringBuilder
import android.text.Spanned
import android.text.style.AlignmentSpan
import com.swmansion.enriched.common.EnrichedConstants
import com.swmansion.enriched.textinput.EnrichedTextInputView
import com.swmansion.enriched.textinput.spans.EnrichedInputCheckboxListSpan
import com.swmansion.enriched.textinput.spans.EnrichedInputOrderedListSpan
import com.swmansion.enriched.textinput.spans.EnrichedInputUnorderedListSpan
import com.swmansion.enriched.textinput.spans.EnrichedSpans
import com.swmansion.enriched.textinput.utils.getParagraphBounds
import com.swmansion.enriched.textinput.utils.getParagraphRangesInRange
import com.swmansion.enriched.textinput.utils.getSafeSpanBoundaries
import com.swmansion.enriched.textinput.utils.removeNonAlignmentZWS

class ListStyles(
  private val view: EnrichedTextInputView,
) {
  private fun <T> getPreviousParagraphSpan(
    spannable: Spannable,
    s: Int,
    type: Class<T>,
  ): T? {
    if (s <= 0) return null

    val (previousParagraphStart, previousParagraphEnd) = spannable.getParagraphBounds(s - 1)
    val spans = spannable.getSpans(previousParagraphStart, previousParagraphEnd, type)

    if (spans.isNotEmpty()) {
      return spans.last()
    }

    return null
  }

  private fun <T> isPreviousParagraphList(
    spannable: Spannable,
    s: Int,
    type: Class<T>,
  ): Boolean {
    val previousSpan = getPreviousParagraphSpan(spannable, s, type)

    return previousSpan != null
  }

  private fun getOrderedListIndex(
    spannable: Spannable,
    s: Int,
  ): Int {
    val span = getPreviousParagraphSpan(spannable, s, EnrichedInputOrderedListSpan::class.java)
    val index = span?.getListIndex() ?: 0
    return index + 1
  }

  private fun setSpan(
    spannable: Spannable,
    name: String,
    start: Int,
    end: Int,
    isChecked: Boolean? = false,
  ) {
    val (safeStart, safeEnd) = spannable.getSafeSpanBoundaries(start, end)

    when (name) {
      EnrichedSpans.UNORDERED_LIST -> {
        val span = EnrichedInputUnorderedListSpan(view.htmlStyle)
        spannable.setSpan(span, safeStart, safeEnd, Spanned.SPAN_EXCLUSIVE_EXCLUSIVE)
      }

      EnrichedSpans.ORDERED_LIST -> {
        val index = getOrderedListIndex(spannable, safeStart)
        val span = EnrichedInputOrderedListSpan(index, view.htmlStyle)
        spannable.setSpan(span, safeStart, safeEnd, Spanned.SPAN_EXCLUSIVE_EXCLUSIVE)
      }

      EnrichedSpans.CHECKBOX_LIST -> {
        val span = EnrichedInputCheckboxListSpan(isChecked ?: false, view.htmlStyle)
        spannable.setSpan(span, safeStart, safeEnd, Spanned.SPAN_EXCLUSIVE_EXCLUSIVE)

        view.layoutManager.invalidateLayout()
      }
    }
  }

  private fun <T> removeSpansForRange(
    spannable: Spannable,
    start: Int,
    end: Int,
    clazz: Class<T>,
  ): Boolean {
    val ssb = spannable as SpannableStringBuilder
    val spans = ssb.getSpans(start, end, clazz)
    if (spans.isEmpty()) return false

    for (span in spans) {
      ssb.removeSpan(span)
    }

    ssb.removeNonAlignmentZWS(start, end)
    return true
  }

  private fun reapplyTypingAlignmentAfterListRemoval(
    spannable: Spannable,
    start: Int,
    end: Int,
  ) {
    val (safeStart, safeEnd) = spannable.getSafeSpanBoundaries(start, end)
    val cursorPos = view.selectionStart.coerceIn(0, spannable.length)

    // Selection changes during list removal can temporarily land in an empty paragraph
    // before alignment spans/placeholders are applied there, which would sync typingAlignment
    // back to ALIGN_NORMAL. Re-sync from surrounding spans at the final cursor anchor first.
    if (!view.isDuringTransaction) {
      view.syncTypingAlignmentWithSelection(cursorPos, cursorPos)
    }

    val paragraphRanges =
      if (safeStart == safeEnd) {
        val (paragraphStart, paragraphEnd) = spannable.getParagraphBounds(safeStart, safeStart)
        listOf(Pair(paragraphStart, paragraphEnd))
      } else {
        spannable.getParagraphRangesInRange(safeStart, safeEnd)
      }

    val rangesToProcess =
      if (paragraphRanges.isEmpty()) {
        val anchor = safeStart.coerceIn(0, spannable.length)
        val (paragraphStart, paragraphEnd) = spannable.getParagraphBounds(anchor, anchor)
        listOf(Pair(paragraphStart, paragraphEnd))
      } else {
        paragraphRanges
      }

    // Process in reverse so ZWS insertions don't shift earlier ranges
    var insertedBeforeCursor = 0
    for ((paragraphStart, paragraphEnd) in rangesToProcess.reversed()) {
      val inserted =
        view.applyTypingAlignmentToParagraphRange(
          paragraphStart,
          paragraphEnd,
          manageCursorExternally = true,
        )
      if (inserted && paragraphStart <= cursorPos) {
        insertedBeforeCursor++
      }
    }

    val finalCursor = (cursorPos + insertedBeforeCursor).coerceIn(0, spannable.length)
    view.setSelection(finalCursor)
    view.layoutManager.invalidateLayout()
    view.requestLayout()
    view.invalidate()
  }

  fun updateOrderedListIndexes(
    text: Spannable,
    position: Int,
  ) {
    val spans = text.getSpans(position + 1, text.length, EnrichedInputOrderedListSpan::class.java)
    val sortedSpans = spans.sortedBy { text.getSpanStart(it) }
    for (span in sortedSpans) {
      val spanStart = text.getSpanStart(span)
      val index = getOrderedListIndex(text, spanStart)
      span.setListIndex(index)
    }
  }

  private fun toggleStyle(
    name: String,
    checkboxState: Boolean?,
  ) {
    if (view.selection == null) return
    val config = EnrichedSpans.listSpans[name] ?: return
    val spannable = view.text as SpannableStringBuilder
    val (start, end) = view.selection.getParagraphSelection()
    val styleStart = view.spanState?.getStart(name)

    if (styleStart != null) {
      view.spanState.setStart(name, null)
      view.runAsATransaction {
        removeSpansForRange(spannable, start, end, config.clazz)
        reapplyTypingAlignmentAfterListRemoval(spannable, start, end)
      }
      view.selection.validateStyles()

      return
    }

    val alignment = captureAlignment(spannable, start, end)

    if (start == end) {
      spannable.insert(start, EnrichedConstants.ZWS_STRING)
      view.spanState?.setStart(name, start + 1)
      removeSpansForRange(spannable, start, end, config.clazz)
      setSpan(spannable, name, start, end + 1, checkboxState)
      applyAlignmentToRange(spannable, start, end + 1, alignment)

      return
    }

    var currentStart = start
    val paragraphs = spannable.substring(start, end).split("\n")
    removeSpansForRange(spannable, start, end, config.clazz)

    for (paragraph in paragraphs) {
      spannable.insert(currentStart, EnrichedConstants.ZWS_STRING)
      val currentEnd = currentStart + paragraph.length + 1
      setSpan(spannable, name, currentStart, currentEnd, checkboxState)
      applyAlignmentToRange(spannable, currentStart, currentEnd, alignment)

      currentStart = currentEnd + 1
    }

    view.spanState?.setStart(name, currentStart)
  }

  private fun captureAlignment(
    spannable: Spannable,
    start: Int,
    end: Int,
  ): Layout.Alignment {
    val alignmentSpans = spannable.getSpans(start, end, AlignmentSpan::class.java)
    return alignmentSpans.firstOrNull()?.alignment ?: Layout.Alignment.ALIGN_NORMAL
  }

  private fun applyAlignmentToRange(
    spannable: Spannable,
    start: Int,
    end: Int,
    alignment: Layout.Alignment,
  ) {
    if (alignment == Layout.Alignment.ALIGN_NORMAL) return
    val (safeStart, safeEnd) = spannable.getSafeSpanBoundaries(start, end)
    if (safeStart >= safeEnd) return

    val existing = spannable.getSpans(safeStart, safeEnd, AlignmentSpan::class.java)
    for (span in existing) {
      spannable.removeSpan(span)
    }
    spannable.setSpan(
      AlignmentSpan.Standard(alignment),
      safeStart,
      safeEnd,
      Spanned.SPAN_EXCLUSIVE_EXCLUSIVE,
    )
  }

  fun toggleStyle(name: String) {
    toggleStyle(name, false)
  }

  fun toggleCheckboxListStyle(checked: Boolean) {
    toggleStyle(EnrichedSpans.CHECKBOX_LIST, checked)
  }

  private fun handleAfterTextChanged(
    s: Editable,
    name: String,
    endCursorPosition: Int,
    previousTextLength: Int,
  ) {
    val config = EnrichedSpans.listSpans[name] ?: return
    val cursorPosition = endCursorPosition.coerceAtMost(s.length)
    val (start, end) = s.getParagraphBounds(cursorPosition)

    val isBackspace = previousTextLength > s.length
    val isNewLine = cursorPosition > 0 && s[cursorPosition - 1] == '\n'
    val isShortcut = config.shortcut?.let { s.substring(start, end).startsWith(it) } ?: false
    val spans = s.getSpans(start, end, config.clazz)

    // Remove spans if cursor is at the start of the paragraph and spans exist
    if (isBackspace && start == cursorPosition && spans.isNotEmpty()) {
      view.runAsATransaction {
        removeSpansForRange(s, start, end, config.clazz)
        val cursorAfterRemoval = view.selectionStart.coerceIn(0, s.length)
        reapplyTypingAlignmentAfterListRemoval(s, cursorAfterRemoval, cursorAfterRemoval)
      }
      return
    }

    if (!isBackspace && isShortcut) {
      s.replace(start, cursorPosition, EnrichedConstants.ZWS_STRING)
      setSpan(s, name, start, start + 1)
      // Inform that new span has been added
      view.selection?.validateStyles()
      return
    }

    if (!isBackspace && isNewLine && isPreviousParagraphList(s, start, config.clazz)) {
      val prevParagraphAlignment =
        if (start > 0) {
          val (prevStart, prevEnd) = s.getParagraphBounds(start - 1)
          captureAlignment(s, prevStart, prevEnd)
        } else {
          Layout.Alignment.ALIGN_NORMAL
        }

      // Check if the span from the previous line "leaked" into this one
      if (spans.isNotEmpty()) {
        val existingSpan = spans[0]
        val spanStart = s.getSpanStart(existingSpan)

        // If the span started before the current paragraph (belongs to the previous item)
        // update it to end at the newline (start - 1)
        if (spanStart < start) {
          val spanFlags = s.getSpanFlags(existingSpan)
          s.setSpan(existingSpan, spanStart, start - 1, spanFlags)
        }
      }

      s.insert(cursorPosition, EnrichedConstants.ZWS_STRING)
      setSpan(s, name, start, end + 1)
      applyAlignmentToRange(s, start, end + 1, prevParagraphAlignment)
      // Inform that new span has been added
      view.selection?.validateStyles()
      return
    }

    if (name === EnrichedSpans.CHECKBOX_LIST) {
      if (spans.isNotEmpty()) {
        val previousSpan = spans[0] as EnrichedInputCheckboxListSpan
        val isChecked = previousSpan.isChecked
        val alignment = captureAlignment(s, start, end)

        for (span in spans) {
          s.removeSpan(span)
        }

        setSpan(s, EnrichedSpans.CHECKBOX_LIST, start, end, isChecked)
        applyAlignmentToRange(s, start, end, alignment)
      }

      return
    }

    if (spans.isNotEmpty()) {
      val alignment = captureAlignment(s, start, end)

      for (span in spans) {
        s.removeSpan(span)
      }

      setSpan(s, name, start, end)
      applyAlignmentToRange(s, start, end, alignment)
    }
  }

  fun afterTextChanged(
    s: Editable,
    endCursorPosition: Int,
    previousTextLength: Int,
  ) {
    handleAfterTextChanged(s, EnrichedSpans.ORDERED_LIST, endCursorPosition, previousTextLength)
    handleAfterTextChanged(s, EnrichedSpans.UNORDERED_LIST, endCursorPosition, previousTextLength)
    handleAfterTextChanged(s, EnrichedSpans.CHECKBOX_LIST, endCursorPosition, previousTextLength)
  }

  fun getStyleRange(): Pair<Int, Int> = view.selection?.getParagraphSelection() ?: Pair(0, 0)

  fun removeStyle(
    name: String,
    start: Int,
    end: Int,
  ): Boolean {
    val config = EnrichedSpans.listSpans[name] ?: return false
    val spannable = view.text as? Spannable ?: return false
    var removed = false
    view.runAsATransaction {
      removed = removeSpansForRange(spannable, start, end, config.clazz)
      if (removed) {
        reapplyTypingAlignmentAfterListRemoval(spannable, start, end)
      }
    }
    return removed
  }
}
