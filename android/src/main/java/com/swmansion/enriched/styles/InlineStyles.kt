package com.swmansion.enriched.styles

import android.text.Editable
import android.text.Spannable
import com.swmansion.enriched.EnrichedTextInputView
import com.swmansion.enriched.spans.EnrichedColoredSpan
import com.swmansion.enriched.spans.EnrichedSpans
import com.swmansion.enriched.utils.getSafeSpanBoundaries

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

  private fun applyColorSpan(
    spannable: Spannable,
    start: Int,
    end: Int,
    color: Int,
  ) {
    val (safeStart, safeEnd) = spannable.getSafeSpanBoundaries(start, end)
    spannable.setSpan(
      EnrichedColoredSpan(view.htmlStyle, color),
      safeStart,
      safeEnd,
      Spannable.SPAN_EXCLUSIVE_EXCLUSIVE,
    )
  }

  private fun splitExistingColorSpans(
    spannable: Spannable,
    start: Int,
    end: Int,
    onRemain: (s: Int, e: Int, color: Int) -> Unit,
  ) {
    val spans = spannable.getSpans(start, end, EnrichedColoredSpan::class.java)
    for (span in spans) {
      val spanStart = spannable.getSpanStart(span)
      val spanEnd = spannable.getSpanEnd(span)
      val color = span.color

      spannable.removeSpan(span)

      if (spanStart < start) {
        onRemain(spanStart, start, color)
      }

      if (spanEnd > end) {
        onRemain(end, spanEnd, color)
      }
    }
  }

  private fun mergeAdjacentColors(spannable: Spannable) {
    val colorSpans =
      spannable
        .getSpans(0, spannable.length, EnrichedColoredSpan::class.java)
        .sortedBy { spannable.getSpanStart(it) }

    var index = 0
    while (index < colorSpans.size - 1) {
      val currentSpan = colorSpans[index]
      val nextSpan = colorSpans[index + 1]

      val currentStart = spannable.getSpanStart(currentSpan)
      val currentEnd = spannable.getSpanEnd(currentSpan)
      val nextStart = spannable.getSpanStart(nextSpan)
      val nextEnd = spannable.getSpanEnd(nextSpan)

      if (currentEnd == nextStart && currentSpan.color == nextSpan.color) {
        spannable.removeSpan(currentSpan)
        spannable.removeSpan(nextSpan)

        applyColorSpan(spannable, currentStart, nextEnd, currentSpan.color)

        return mergeAdjacentColors(spannable)
      }

      index++
    }
  }

  private fun isFullyColoredWith(
    spannable: Spannable,
    start: Int,
    end: Int,
    color: Int,
  ): Boolean {
    val spans = spannable.getSpans(start, end, EnrichedColoredSpan::class.java)
    if (spans.isEmpty()) return false

    val allSame = spans.all { it.color == color }

    if (!allSame) {
      return false
    }

    val minStart = spans.minOf { spannable.getSpanStart(it) }
    val maxEnd = spans.maxOf { spannable.getSpanEnd(it) }

    return minStart <= start && maxEnd >= end
  }

  fun setColorStyle(color: Int) {
    val (start, end) = view.selection?.getInlineSelection() ?: return
    val spannable = view.text as Spannable

    if (start == end) {
      val spanState = view.spanState
      if (spanState?.colorStart != null && spanState.typingColor == color) {
        view.spanState.setColorStart(null, null)
      } else {
        view.spanState?.setColorStart(start, color)
      }
      return
    }

    if (isFullyColoredWith(spannable, start, end, color)) {
      removeColorRange(start, end)
      view.spanState?.setColorStart(null, null)
      view.selection.validateStyles()
      return
    }

    splitExistingColorSpans(spannable, start, end) { spanStart, spanEnd, existingColor ->
      applyColorSpan(spannable, spanStart, spanEnd, existingColor)
    }

    applyColorSpan(spannable, start, end, color)

    mergeAdjacentColors(spannable)

    view.spanState?.setColorStart(null, null)
    view.selection.validateStyles()
  }

  private fun removeColorRange(
    start: Int,
    end: Int,
  ) {
    val spannable = view.text as Spannable

    splitExistingColorSpans(spannable, start, end) { spanStart, spanEnd, color ->
      if (spanStart < start) applyColorSpan(spannable, spanStart, start, color)
      if (spanEnd > end) applyColorSpan(spannable, end, spanEnd, color)
    }
  }

  fun removeColorSpan() {
    val (start, end) = view.selection?.getInlineSelection() ?: return

    if (start == end) {
      view.spanState?.setColorStart(null, null)
      return
    }

    removeColorRange(start, end)

    view.spanState?.setColorStart(null, null)
    view.selection.validateStyles()
  }

  private fun applyTypingColorIfActive(
    spannable: Spannable,
    cursor: Int,
  ) {
    val state = view.spanState ?: return
    val colorStart = state.colorStart ?: return
    val color = state.typingColor ?: return

    val existing =
      spannable
        .getSpans(colorStart, colorStart, EnrichedColoredSpan::class.java)
        .firstOrNull { it.color == color }

    if (existing != null) {
      val spanStart = spannable.getSpanStart(existing)
      val spanEnd = spannable.getSpanEnd(existing)

      if (cursor > spanEnd) {
        spannable.removeSpan(existing)
        applyColorSpan(spannable, spanStart, cursor, color)
      }

      view.spanState.setColorStart(cursor, color)
      return
    }

    applyColorSpan(spannable, colorStart, cursor, color)
    view.spanState.setColorStart(cursor, color)
  }

  fun afterTextChanged(
    editable: Editable,
    endCursorPosition: Int,
  ) {
    for ((style, config) in EnrichedSpans.inlineSpans) {
      val start = view.spanState?.getStart(style) ?: continue
      var end = endCursorPosition
      if (config.clazz == EnrichedColoredSpan::class.java) {
        applyTypingColorIfActive(editable, end)
        continue
      }
      val spans = editable.getSpans(start, end, config.clazz)

      for (span in spans) {
        end = editable.getSpanEnd(span).coerceAtLeast(end)
        editable.removeSpan(span)
      }

      setSpan(editable, config.clazz, start, end)
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
