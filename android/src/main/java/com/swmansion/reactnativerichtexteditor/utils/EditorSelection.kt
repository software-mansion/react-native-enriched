package com.swmansion.reactnativerichtexteditor.utils

import android.text.Spannable
import com.swmansion.reactnativerichtexteditor.ReactNativeRichTextEditorView
import com.swmansion.reactnativerichtexteditor.spans.EditorSpans

class EditorSelection(private val editorView: ReactNativeRichTextEditorView) {
  var start: Int = 0
  var end: Int = 0

  fun onSelection(selStart: Int, selEnd: Int) {
    start = selStart
    end = selEnd

    this.validateStyles()
  }

  fun validateStyles() {
    val state = editorView.spanState ?: return

    for ((style, config) in EditorSpans.inlineSpans) {
      state.setStart(style, getInlineStyleStart(config.clazz))
    }

    for((style, config) in EditorSpans.paragraphSpans) {
      state.setStart(style, getParagraphStyleStart(config.clazz))
    }
  }

  fun getInlineSelection(): Pair<Int, Int> {
    val finalStart = start.coerceAtMost(end).coerceAtLeast(0)
    val finalEnd = end.coerceAtLeast(start).coerceAtLeast(0)

    return Pair(finalStart, finalEnd)
  }

  private fun <T>getInlineStyleStart(type: Class<T>): Int? {
    val (start, end) = getInlineSelection()
    val spannable = editorView.text as Spannable
    val spans = spannable.getSpans(start, end, type)
    var styleStart: Int? = null

    for (span in spans) {
      val spanStart = spannable.getSpanStart(span)
      val spanEnd = spannable.getSpanEnd(span)

      if (start == end && start == spanStart) {
        styleStart = null
      } else if (start >= spanStart && end <= spanEnd) {
        styleStart = spanStart
      }
    }

    return styleStart
  }

  fun getParagraphBounds(spannable: Spannable, index: Int): Pair<Int, Int> {
    return getParagraphBounds(spannable, index, index)
  }

  fun getParagraphBounds(spannable: Spannable, start: Int, end: Int): Pair<Int, Int> {
    var startPosition = start.coerceAtLeast(0).coerceAtMost(spannable.length)
    var endPosition = end.coerceAtLeast(0).coerceAtMost(spannable.length)

    // Find the start of the paragraph
    while (startPosition > 0 && spannable[startPosition - 1] != '\n') {
      startPosition--
    }

    // Find the end of the paragraph
    while (endPosition < spannable.length && spannable[endPosition] != '\n') {
      endPosition++
    }

    return Pair(startPosition, endPosition)
  }

  fun getParagraphSelection(): Pair<Int, Int> {
    val (currentStart, currentEnd) = getInlineSelection()
    val spannable = editorView.text as Spannable
    return getParagraphBounds(spannable, currentStart, currentEnd)
  }

  private fun <T>getParagraphStyleStart(type: Class<T>): Int? {
    val (start, end) = getParagraphSelection()
    val spannable = editorView.text as Spannable
    val spans = spannable.getSpans(start, end, type)
    var styleStart: Int? = null

    for (span in spans) {
      val spanStart = spannable.getSpanStart(span)
      val spanEnd = spannable.getSpanEnd(span)

      if (start >= spanStart && end <= spanEnd) {
        styleStart = spanStart
        break
      }
    }

    return styleStart
  }
}
