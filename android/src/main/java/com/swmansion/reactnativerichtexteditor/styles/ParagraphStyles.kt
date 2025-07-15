package com.swmansion.reactnativerichtexteditor.styles

import android.text.Editable
import android.text.Spannable
import android.text.SpannableStringBuilder
import com.swmansion.reactnativerichtexteditor.ReactNativeRichTextEditorView
import com.swmansion.reactnativerichtexteditor.spans.EditorSpans
import com.swmansion.reactnativerichtexteditor.utils.getParagraphBounds
import com.swmansion.reactnativerichtexteditor.utils.getSafeSpanBoundaries

class ParagraphStyles(private val editorView: ReactNativeRichTextEditorView) {
  private fun <T>setSpan(spannable: Spannable, type: Class<T>, start: Int, end: Int) {
    val span = type.getDeclaredConstructor(RichTextStyle::class.java).newInstance(editorView.richTextStyle)
    val (safeStart, safeEnd) = spannable.getSafeSpanBoundaries(start, end)
    spannable.setSpan(span, safeStart, safeEnd, Spannable.SPAN_EXCLUSIVE_EXCLUSIVE)
  }

  private fun <T>removeSpansForRange(spannable: Spannable, start: Int, end: Int, clazz: Class<T>) {
    val ssb = spannable as SpannableStringBuilder
    var finalStart = start
    var finalEnd = end

    val spans = ssb.getSpans(start, end, clazz)
    if (spans.isEmpty()) return

    for (span in spans) {
      finalStart = ssb.getSpanStart(span).coerceAtMost(finalStart)
      finalEnd = ssb.getSpanEnd(span).coerceAtLeast(finalEnd)
      ssb.removeSpan(span)
    }

    ssb.replace(finalStart, finalEnd, ssb.substring(finalStart, finalEnd).replace("\u200B", ""))
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

  private fun <T>isSpanEnabledInNextLine(spannable: Spannable, index: Int, type: Class<T>): Boolean {
    val selection = editorView.selection ?: return false
    if (index + 1 >= spannable.length) return false
    val (start, end) = selection.getParagraphSelection()

    val spans = spannable.getSpans(start, end, type)
    return spans.isNotEmpty()
  }

  fun afterTextChanged(s: Editable, endPosition: Int, previousTextLength: Int) {
    var endCursorPosition = endPosition
    val isBackspace = s.length < previousTextLength
    val isNewLine = endCursorPosition == 0 || endCursorPosition > 0 && s[endCursorPosition - 1] == '\n'

    for ((style, config) in EditorSpans.paragraphSpans) {
      val spanState = editorView.spanState ?: continue
      val styleStart = spanState.getStart(style) ?: continue

      if (isNewLine) {
        if (!config.isContinuous) {
          spanState.setStart(style, null)
          continue
        }

        if (isBackspace) {
          endCursorPosition -= 1
          editorView.spanState.setStart(style, null)
        } else {
          s.insert(endCursorPosition, "\u200B")
          endCursorPosition += 1
        }
      }

      var (start, end) = s.getParagraphBounds(styleStart, endCursorPosition)
      val isNotEndLineSpan = isSpanEnabledInNextLine(s, end, config.clazz)
      val spans = s.getSpans(start, end, config.clazz)

      for (span in spans) {
        if (isNotEndLineSpan) {
          start = s.getSpanStart(span).coerceAtMost(start)
          end = s.getSpanEnd(span).coerceAtLeast(end)
        }

        s.removeSpan(span)
      }

      setSpan(s, config.clazz, start, end)
    }
  }

  fun toggleStyle(name: String) {
    if (editorView.selection == null) return
    val spannable = editorView.text as SpannableStringBuilder
    var (start, end) = editorView.selection.getParagraphSelection()
    val config = EditorSpans.paragraphSpans[name] ?: return
    val type = config.clazz

    val styleStart = editorView.spanState?.getStart(name)

    if (styleStart != null) {
      editorView.spanState.setStart(name, null)
      removeSpansForRange(spannable, start, end, type)
      editorView.selection.validateStyles()

      return
    }

    if (start == end) {
      spannable.insert(start, "\u200B")
      editorView.spanState?.setStart(name, start + 1)
      setAndMergeSpans(spannable, type, start, end + 1)

      return
    }

    var currentStart = start
    var currentEnd = currentStart
    val paragraphs = spannable.substring(start, end).split("\n")

    for (paragraph in paragraphs) {
      spannable.insert(currentStart, "\u200B")
      currentEnd = currentStart + paragraph.length + 1
      currentStart = currentEnd + 1
    }

    editorView.spanState?.setStart(name, start)
    setAndMergeSpans(spannable, type, start, currentEnd)
  }

  fun getStyleRange(): Pair<Int, Int> {
    return editorView.selection?.getParagraphSelection() ?: Pair(0, 0)
  }

  fun removeStyle(name: String, start: Int, end: Int) {
    val config = EditorSpans.paragraphSpans[name] ?: return
    val spannable = editorView.text as Spannable
    removeSpansForRange(spannable, start, end, config.clazz)
  }
}
