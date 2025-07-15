package com.swmansion.reactnativerichtexteditor.styles

import android.text.Editable
import android.text.Spannable
import android.text.SpannableStringBuilder
import android.text.Spanned
import com.swmansion.reactnativerichtexteditor.ReactNativeRichTextEditorView
import com.swmansion.reactnativerichtexteditor.spans.EditorOrderedListSpan
import com.swmansion.reactnativerichtexteditor.spans.EditorSpans
import com.swmansion.reactnativerichtexteditor.spans.EditorUnorderedListSpan
import com.swmansion.reactnativerichtexteditor.utils.getParagraphBounds
import com.swmansion.reactnativerichtexteditor.utils.getSafeSpanBoundaries

class ListStyles(private val editorView: ReactNativeRichTextEditorView) {
  private fun <T>getPreviousParagraphSpan(spannable: Spannable, s: Int, type: Class<T>): T? {
    if (s <= 0) return null

    val (previousParagraphStart, previousParagraphEnd) = spannable.getParagraphBounds(s - 1)
    val spans = spannable.getSpans(previousParagraphStart, previousParagraphEnd, type)

    if (spans.isNotEmpty()) {
      return spans.last()
    }

    return null
  }

  private fun <T>isPreviousParagraphList(spannable: Spannable, s: Int, type: Class<T>): Boolean {
    val previousSpan = getPreviousParagraphSpan(spannable, s, type)

    return previousSpan != null
  }

  private fun getOrderedListIndex(spannable: Spannable, s: Int): Int {
    val span = getPreviousParagraphSpan(spannable, s, EditorOrderedListSpan::class.java)
    val index = span?.getIndex() ?: 0
    return index + 1
  }

  private fun setSpan(spannable: Spannable, name: String, start: Int, end: Int) {
    val (safeStart, safeEnd) = spannable.getSafeSpanBoundaries(start, end)

    if (name == EditorSpans.UNORDERED_LIST) {
      val span = EditorUnorderedListSpan(editorView.richTextStyle)
      spannable.setSpan(span, safeStart, safeEnd, Spanned.SPAN_EXCLUSIVE_EXCLUSIVE)
      return
    }

    if (name == EditorSpans.ORDERED_LIST) {
      val index = getOrderedListIndex(spannable, safeStart)
      val span = EditorOrderedListSpan(index, editorView.richTextStyle)
      spannable.setSpan(span, safeStart, safeEnd, Spanned.SPAN_EXCLUSIVE_EXCLUSIVE)
    }
  }

  private fun <T>removeSpansForRange(spannable: Spannable, start: Int, end: Int, clazz: Class<T>): Boolean {
    val ssb = spannable as SpannableStringBuilder
    val spans = ssb.getSpans(start, end, clazz)
    if (spans.isEmpty()) return false

    ssb.replace(start, end, ssb.substring(start, end).replace("\u200B", ""))

    for (span in spans) {
      ssb.removeSpan(span)
    }

    return true
  }

  fun updateOrderedListIndexes(text: Spannable, position: Int) {
    val spans = text.getSpans(position + 1, text.length, EditorOrderedListSpan::class.java)
    for (span in spans) {
      val spanStart = text.getSpanStart(span)
      val index = getOrderedListIndex(text, spanStart)
      span.setIndex(index)
    }
  }

  fun toggleStyle(name: String) {
    if (editorView.selection == null) return
    val config = EditorSpans.listSpans[name] ?: return
    val spannable = editorView.text as SpannableStringBuilder
    var (start, end) = editorView.selection.getParagraphSelection()
    val styleStart = editorView.spanState?.getStart(name)

    if (styleStart != null) {
      editorView.spanState.setStart(name, null)
      removeSpansForRange(spannable, start, end, config.clazz)
      editorView.selection.validateStyles()

      return
    }

    if (start == end) {
      spannable.insert(start, "\u200B")
      editorView.spanState?.setStart(name, start + 1)
      removeSpansForRange(spannable, start, end, config.clazz)
      setSpan(spannable, name, start, end + 1)

      return
    }

    var currentStart = start
    val paragraphs = spannable.substring(start, end).split("\n")
    removeSpansForRange(spannable, start, end, config.clazz)

    for (paragraph in paragraphs) {
      spannable.insert(currentStart, "\u200B")
      val currentEnd = currentStart + paragraph.length + 1
      setSpan(spannable, name, currentStart, currentEnd)

      currentStart = currentEnd + 1
    }

    editorView.spanState?.setStart(name, currentStart)
  }

  private fun handleAfterTextChanged(s: Editable, name: String, endCursorPosition: Int, previousTextLength: Int) {
    val config = EditorSpans.listSpans[name] ?: return
    val cursorPosition = endCursorPosition.coerceAtMost(s.length)
    val (start, end) = s.getParagraphBounds(cursorPosition)

    val isBackspace = previousTextLength > s.length
    val isNewLine = cursorPosition > 0 && s[cursorPosition - 1] == '\n'
    val isShortcut = s.substring(start, end).startsWith(config.shortcut)
    val spans = s.getSpans(start, end, config.clazz)

    // Remove spans if cursor is at the start of the paragraph and spans exist
    if (isBackspace && start == cursorPosition && spans.isNotEmpty()) {
      removeSpansForRange(s, start, end, config.clazz)
      return
    }

    if (!isBackspace && isShortcut) {
      s.replace(start, cursorPosition, "\u200B")
      setSpan(s, name, start, start + 1)
      // Inform that new span has been added
      editorView.selection?.validateStyles()
      return
    }

    if (!isBackspace && isNewLine && isPreviousParagraphList(s, start, config.clazz)) {
      s.insert(cursorPosition, "\u200B")
      setSpan(s, name, start, end + 1)
      // Inform that new span has been added
      editorView.selection?.validateStyles()
      return
    }

    if (spans.isNotEmpty()) {
      for (span in spans) {
        s.removeSpan(span)
      }

      setSpan(s, name, start, end)
    }
  }

  fun afterTextChanged(s: Editable, endCursorPosition: Int, previousTextLength: Int) {
    handleAfterTextChanged(s, EditorSpans.ORDERED_LIST, endCursorPosition, previousTextLength)
    handleAfterTextChanged(s, EditorSpans.UNORDERED_LIST, endCursorPosition, previousTextLength)
  }

  fun getStyleRange(): Pair<Int, Int> {
    return editorView.selection?.getParagraphSelection() ?: Pair(0, 0)
  }

  fun removeStyle(name: String, start: Int, end: Int): Boolean {
    val config = EditorSpans.listSpans[name] ?: return false
    val spannable = editorView.text as Spannable
    return removeSpansForRange(spannable, start, end, config.clazz)
  }
}
