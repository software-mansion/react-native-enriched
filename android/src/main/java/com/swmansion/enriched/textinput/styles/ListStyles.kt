package com.swmansion.enriched.textinput.styles

import android.text.Editable
import android.text.Spannable
import android.text.SpannableStringBuilder
import android.text.Spanned
import com.swmansion.enriched.textinput.EnrichedTextInputView
import com.swmansion.enriched.textinput.spans.EnrichedCheckboxListSpan
import com.swmansion.enriched.textinput.spans.EnrichedOrderedListSpan
import com.swmansion.enriched.textinput.spans.EnrichedSpans
import com.swmansion.enriched.textinput.spans.EnrichedUnorderedListSpan
import com.swmansion.enriched.textinput.utils.EnrichedConstants
import com.swmansion.enriched.textinput.utils.getParagraphBounds
import com.swmansion.enriched.textinput.utils.getSafeSpanBoundaries
import com.swmansion.enriched.textinput.utils.removeZWS

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
    val span = getPreviousParagraphSpan(spannable, s, EnrichedOrderedListSpan::class.java)
    val index = span?.getIndex() ?: 0
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
        val span = EnrichedUnorderedListSpan(view.htmlStyle)
        spannable.setSpan(span, safeStart, safeEnd, Spanned.SPAN_EXCLUSIVE_EXCLUSIVE)
      }

      EnrichedSpans.ORDERED_LIST -> {
        val index = getOrderedListIndex(spannable, safeStart)
        val span = EnrichedOrderedListSpan(index, view.htmlStyle)
        spannable.setSpan(span, safeStart, safeEnd, Spanned.SPAN_EXCLUSIVE_EXCLUSIVE)
      }

      EnrichedSpans.CHECKBOX_LIST -> {
        val span = EnrichedCheckboxListSpan(isChecked ?: false, view.htmlStyle)
        spannable.setSpan(span, safeStart, safeEnd, Spanned.SPAN_EXCLUSIVE_EXCLUSIVE)

        // Invalidate layout to update checkbox drawing in case checkbox is bigger than line height
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

    ssb.removeZWS(start, end)
    return true
  }

  fun updateOrderedListIndexes(
    text: Spannable,
    position: Int,
  ) {
    val spans = text.getSpans(position + 1, text.length, EnrichedOrderedListSpan::class.java)
    val sortedSpans = spans.sortedBy { text.getSpanStart(it) }
    for (span in sortedSpans) {
      val spanStart = text.getSpanStart(span)
      val index = getOrderedListIndex(text, spanStart)
      span.setIndex(index)
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
      removeSpansForRange(spannable, start, end, config.clazz)
      view.selection.validateStyles()

      return
    }

    if (start == end) {
      spannable.insert(start, EnrichedConstants.ZWS_STRING)
      view.spanState?.setStart(name, start + 1)
      removeSpansForRange(spannable, start, end, config.clazz)
      setSpan(spannable, name, start, end + 1, checkboxState)

      return
    }

    var currentStart = start
    val paragraphs = spannable.substring(start, end).split("\n")
    removeSpansForRange(spannable, start, end, config.clazz)

    for (paragraph in paragraphs) {
      spannable.insert(currentStart, EnrichedConstants.ZWS_STRING)
      val currentEnd = currentStart + paragraph.length + 1
      setSpan(spannable, name, currentStart, currentEnd, checkboxState)

      currentStart = currentEnd + 1
    }

    view.spanState?.setStart(name, currentStart)
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
      removeSpansForRange(s, start, end, config.clazz)
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
      s.insert(cursorPosition, EnrichedConstants.ZWS_STRING)
      setSpan(s, name, start, end + 1)
      // Inform that new span has been added
      view.selection?.validateStyles()
      return
    }

    if (name === EnrichedSpans.CHECKBOX_LIST) {
      if (spans.isNotEmpty()) {
        val previousSpan = spans[0] as EnrichedCheckboxListSpan
        val isChecked = previousSpan.isChecked

        for (span in spans) {
          s.removeSpan(span)
        }

        setSpan(s, EnrichedSpans.CHECKBOX_LIST, start, end, isChecked)
      }

      return
    }

    if (spans.isNotEmpty()) {
      for (span in spans) {
        s.removeSpan(span)
      }

      setSpan(s, name, start, end)
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
    val spannable = view.text as Spannable
    return removeSpansForRange(spannable, start, end, config.clazz)
  }
}
