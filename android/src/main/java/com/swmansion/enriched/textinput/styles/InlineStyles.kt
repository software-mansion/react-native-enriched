package com.swmansion.enriched.textinput.styles

import android.text.Editable
import android.text.Spannable
import com.swmansion.enriched.textinput.EnrichedTextInputView
import com.swmansion.enriched.textinput.spans.EnrichedSpans
import com.swmansion.enriched.textinput.utils.getSafeSpanBoundaries

class InlineStyles(
  private val view: EnrichedTextInputView,
) {
  private fun <T> setSpan(
    spannable: Spannable,
    type: Class<T>,
    start: Int,
    end: Int,
  ) {
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

    val span = type.getDeclaredConstructor(HtmlStyle::class.java).newInstance(view.htmlStyle)
    val (safeStart, safeEnd) = spannable.getSafeSpanBoundaries(minimum, maximum)
    spannable.setSpan(span, safeStart, safeEnd, Spannable.SPAN_EXCLUSIVE_EXCLUSIVE)
  }

  private fun <T> setAndMergeSpans(
    spannable: Spannable,
    type: Class<T>,
    start: Int,
    end: Int,
  ) {
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
      if (spanStart == -1 || spanEnd == -1) continue

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

  fun afterTextChanged(
    s: Editable,
    endCursorPosition: Int,
  ) {
    for ((style, config) in EnrichedSpans.inlineSpans) {
      val start = view.spanState?.getStart(style) ?: continue
      var end = endCursorPosition
      val spans = s.getSpans(start, end, config.clazz)

      for (span in spans) {
        end = s.getSpanEnd(span).coerceAtLeast(end)
        s.removeSpan(span)
      }

      setSpan(s, config.clazz, start, end)
    }
  }

  fun toggleStyle(name: String) {
    if (view.selection == null) return
    val (start, end) = view.selection.getInlineSelection()
    val config = EnrichedSpans.inlineSpans[name] ?: return
    val type = config.clazz

    // We either start or end current span
    if (start == end) {
      val styleStart = view.spanState?.getStart(name)

      if (styleStart != null) {
        view.spanState.setStart(name, null)
      } else {
        view.spanState?.setStart(name, start)
      }

      return
    }

    val spannable = view.text as Spannable
    setAndMergeSpans(spannable, type, start, end)
    view.selection.validateStyles()
  }

  fun removeStyle(
    name: String,
    start: Int,
    end: Int,
  ): Boolean {
    val config = EnrichedSpans.inlineSpans[name] ?: return false
    val spannable = view.text as Spannable
    val spans = spannable.getSpans(start, end, config.clazz)
    if (spans.isEmpty()) return false

    for (span in spans) {
      spannable.removeSpan(span)
    }

    return true
  }

  fun getStyleRange(): Pair<Int, Int> = view.selection?.getInlineSelection() ?: Pair(0, 0)
}
