package com.swmansion.reactnativerichtexteditor.styles

import android.text.Editable
import android.text.Spannable
import com.swmansion.reactnativerichtexteditor.ReactNativeRichTextEditorView
import com.swmansion.reactnativerichtexteditor.spans.EditorSpans

class InlineStyles(private val editorView: ReactNativeRichTextEditorView) {
  private fun <T>setSpan(spannable: Spannable, type: Class<T>, start: Int, end: Int) {
    val previousSpanStart = (start - 1).coerceAtLeast(0)
    val previousSpanEnd = previousSpanStart + 1
    val nextSpanStart = (end + 1).coerceAtMost(spannable.length)
    val nextSpanEnd = (nextSpanStart + 1).coerceAtMost(spannable.length)
    val previousSpans = spannable.getSpans(previousSpanStart, previousSpanEnd, type)
    val nextSpans = spannable.getSpans(nextSpanStart, nextSpanEnd, type)
    var minimum = start
    var maximum = end

    for (span in previousSpans) {
      val spanStart = spannable.getSpanStart(span)
      minimum = spanStart.coerceAtMost(minimum)
    }

    for (span in nextSpans) {
      val spanEnd = spannable.getSpanEnd(span)
      maximum = spanEnd.coerceAtLeast(maximum)
    }

    val spans = spannable.getSpans(minimum, maximum, type)
    for (span in spans) {
      spannable.removeSpan(span)
    }

    val span = type.getDeclaredConstructor(RichTextStyle::class.java).newInstance(editorView.richTextStyle)
    spannable.setSpan(span, minimum.coerceAtMost(maximum), maximum.coerceAtLeast(minimum), Spannable.SPAN_EXCLUSIVE_EXCLUSIVE)
  }

  private fun <T>setAndMergeSpans(spannable: Spannable, type: Class<T>, start: Int, end: Int) {
    val spans = spannable.getSpans(start, end, type)

    // No spans setup for current selection, means we just need to assign new span
    if (spans.isEmpty()) {
      setSpan(spannable, type, start, end)
      return
    }

    var setSpanOnFinish = false

    // Some spans are present, we have to remove spans and (optionally) apply new spans
    for (span in spans) {
      val spanStart = spannable.getSpanStart(span)
      val spanEnd = spannable.getSpanEnd(span)
      var finalStart: Int? = null
      var finalEnd: Int? = null

      spannable.removeSpan(span)

      if (start == spanStart && end == spanEnd) {
        setSpanOnFinish = false
      } else if (start > spanStart && end < spanEnd) {
        setSpan(spannable, type, spanStart, start)
        setSpan(spannable, type, end, spanEnd)
      } else if (start == spanStart && end < spanEnd) {
        finalStart = end
        finalEnd = spanEnd
      } else if (start > spanStart && end == spanEnd) {
        finalStart = spanStart
        finalEnd = start
      } else if (start > spanStart) {
        finalStart = spanStart
        finalEnd = end
      } else if (start < spanStart && end < spanEnd) {
        finalStart = start
        finalEnd = spanEnd
      } else {
        setSpanOnFinish = true
      }

      if (!setSpanOnFinish && finalStart != null && finalEnd != null) {
        setSpan(spannable, type, finalStart, finalEnd)
      }
    }

    if (setSpanOnFinish) {
      setSpan(spannable, type, start, end)
    }
  }

  fun afterTextChanged(s: Editable, endCursorPosition: Int) {
    for ((style, config) in EditorSpans.inlineSpans) {
      val start = editorView.spanState?.getStart(style) ?: continue
      var end = endCursorPosition
      val spans = s.getSpans(start, end, config.clazz)

      for (span in spans) {
        s.removeSpan(span)
      }

      setSpan(s, config.clazz, start, end)
    }
  }

  fun toggleStyle(name: String) {
    if (editorView.selection == null) return
    val (start, end) = editorView.selection.getInlineSelection()
    val config = EditorSpans.inlineSpans[name] ?: return
    val type = config.clazz

    // We either start or end current span
    if (start == end) {
      val styleStart = editorView.spanState?.getStart(name)

      if (styleStart != null) {
        editorView.spanState.setStart(name, null)
      } else {
        editorView.spanState?.setStart(name, start)
      }

      return
    }

    val spannable = editorView.text as Spannable
    setAndMergeSpans(spannable, type, start, end)
    editorView.selection.validateStyles()
  }
}
