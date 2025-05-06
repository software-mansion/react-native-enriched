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

    for ((style, config) in EditorSpans.specialStyles) {
      state.setStart(style, getSpecialStyleStart(config.clazz))
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

  private fun <T>getSpecialStyleStart(type: Class<T>): Int? {
    val (start, end) = getInlineSelection()
    val spannable = editorView.text as Spannable
    val spans = spannable.getSpans(start, end, type)

    for (span in spans) {
      val spanStart = spannable.getSpanStart(span)
      val spanEnd = spannable.getSpanEnd(span)

      if (start >= spanStart && end <= spanEnd) {
        return spanStart
      }
    }

    return null
  }
}
