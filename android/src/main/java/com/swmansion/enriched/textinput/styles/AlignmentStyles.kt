package com.swmansion.enriched.textinput.styles

import android.text.Editable
import android.text.Spannable
import android.text.SpannableStringBuilder
import com.swmansion.enriched.common.EnrichedConstants
import com.swmansion.enriched.textinput.EnrichedTextInputView
import com.swmansion.enriched.textinput.spans.EnrichedInputAlignmentSpan
import com.swmansion.enriched.textinput.spans.EnrichedInputCheckboxListSpan
import com.swmansion.enriched.textinput.spans.EnrichedInputOrderedListSpan
import com.swmansion.enriched.textinput.spans.EnrichedInputUnorderedListSpan
import com.swmansion.enriched.textinput.utils.getParagraphBounds
import com.swmansion.enriched.textinput.utils.getSafeSpanBoundaries
import com.swmansion.enriched.textinput.utils.safelyInsertZWS

class AlignmentStyles(
  private val view: EnrichedTextInputView,
) {
  private fun setAlignmentSpan(
    spannable: Spannable,
    cssValue: String,
    start: Int,
    end: Int,
    flags: Int = Spannable.SPAN_EXCLUSIVE_EXCLUSIVE,
  ) {
    val (safeStart, safeEnd) = spannable.getSafeSpanBoundaries(start, end)
    spannable.setSpan(
      EnrichedInputAlignmentSpan(cssValue),
      safeStart,
      safeEnd,
      flags,
    )
  }

  private fun toCssValue(alignment: String): String =
    when (alignment) {
      "center" -> "center"
      "right" -> "right"
      "left" -> "left"
      else -> "auto"
    }

  private fun getActiveListSpanType(
    spannable: Spannable,
    start: Int,
    end: Int,
  ): Class<*>? {
    if (spannable.getSpans(start, end, EnrichedInputUnorderedListSpan::class.java).isNotEmpty()) {
      return EnrichedInputUnorderedListSpan::class.java
    }
    if (spannable.getSpans(start, end, EnrichedInputOrderedListSpan::class.java).isNotEmpty()) {
      return EnrichedInputOrderedListSpan::class.java
    }
    if (spannable.getSpans(start, end, EnrichedInputCheckboxListSpan::class.java).isNotEmpty()) {
      return EnrichedInputCheckboxListSpan::class.java
    }
    return null
  }

  /**
   * Expands [start, end] to cover all contiguous paragraphs that belong to the same list type.
   * Alignment changes must apply to entire lists, not individual items within them.
   */
  private fun expandRangeToContiguousList(
    spannable: Spannable,
    start: Int,
    end: Int,
  ): Pair<Int, Int> {
    if (spannable.isEmpty()) return Pair(start, end)

    var expandedStart = start
    var expandedEnd = end

    // Expand backward through paragraphs of the same list type.
    var (currentParaStart, currentParaEnd) = spannable.getParagraphBounds(start)
    val activeStartType = getActiveListSpanType(spannable, currentParaStart, currentParaEnd)

    if (activeStartType != null) {
      expandedStart = currentParaStart
      while (currentParaStart > 0) {
        val (prevParaStart, prevParaEnd) = spannable.getParagraphBounds(currentParaStart - 1)
        if (getActiveListSpanType(spannable, prevParaStart, prevParaEnd) == activeStartType) {
          expandedStart = prevParaStart
          currentParaStart = prevParaStart
        } else {
          break
        }
      }
    }

    // Expand forward through paragraphs of the same list type.
    val endLoc = if (end > start) end - 1 else start
    var (endParaStart, endParaEnd) = spannable.getParagraphBounds(endLoc)
    val activeEndType = getActiveListSpanType(spannable, endParaStart, endParaEnd)

    if (activeEndType != null) {
      expandedEnd = endParaEnd
      while (endParaEnd < spannable.length) {
        val nextCursor = endParaEnd + 1
        if (nextCursor >= spannable.length) break

        val (nextParaStart, nextParaEnd) = spannable.getParagraphBounds(nextCursor)
        if (getActiveListSpanType(spannable, nextParaStart, nextParaEnd) == activeEndType) {
          expandedEnd = nextParaEnd
          endParaEnd = nextParaEnd
        } else {
          break
        }
      }
    }

    return Pair(expandedStart, expandedEnd)
  }

  fun afterTextChanged(
    s: Editable,
    cursorPosition: Int,
    deletedText: String,
    anchorAlignmentToRestore: String? = null,
  ) {
    val isJustNewline = cursorPosition > 0 && s[cursorPosition - 1] == '\n'
    val isOtherStyleInjectedZws =
      cursorPosition > 1 &&
        s[cursorPosition - 1].toString() == EnrichedConstants.ZWS_STRING &&
        s[cursorPosition - 2] == '\n'
    val isNewLineInserted = deletedText.isEmpty() && (isJustNewline || isOtherStyleInjectedZws)

    val includesNewlineDeletion = deletedText.contains('\n')
    val isZwsDeleted = deletedText == EnrichedConstants.ZWS_STRING

    // Track cursor separately because deleting a newline shifts text indices.
    var activeCursor = cursorPosition

    // Exit early if no alignment spans exist in the current or previous paragraph.
    if (anchorAlignmentToRestore == null) {
      val bounded = activeCursor.coerceIn(0, s.length)
      val (paraStart, paraEnd) = s.getParagraphBounds(bounded)
      val prevStart = if (paraStart > 0) s.getParagraphBounds(paraStart - 1).first else 0
      if (s.getSpans(prevStart, paraEnd, EnrichedInputAlignmentSpan::class.java).isEmpty()) {
        view.selection?.validateStyles()
        return
      }
    }

    if (isNewLineInserted) {
      activeCursor = handleNewlineInheritance(s, activeCursor, isOtherStyleInjectedZws)
      autoStretchAlignmentSpan(s, activeCursor)
    } else if (isZwsDeleted && anchorAlignmentToRestore != null) {
      val (paraStart, paraEnd) = s.getParagraphBounds(activeCursor)
      (s as SpannableStringBuilder).safelyInsertZWS(activeCursor)
      if (paraStart == paraEnd) {
        setAlignmentSpan(s, anchorAlignmentToRestore, activeCursor, activeCursor + 1)
      }
      autoStretchAlignmentSpan(s, activeCursor)
    } else {
      if (isZwsDeleted) {
        activeCursor = handleZwsBackspace(s, activeCursor)
      }
      view.runAsATransaction {
        if (includesNewlineDeletion) {
          activeCursor = handleParagraphMerge(s, activeCursor)
        }

        autoStretchAlignmentSpan(s, activeCursor)
      }
    }

    view.selection?.validateStyles()
  }

  /**
   * Ensures the alignment span perfectly wraps the paragraph boundaries at [activeCursor].
   * If a newline was inserted mid-paragraph the span is split; otherwise it is stretched
   * to cover any newly typed text.
   */
  private fun autoStretchAlignmentSpan(
    s: Editable,
    activeCursor: Int,
  ) {
    val (paraStart, paraEnd) = s.getParagraphBounds(activeCursor)
    val spans = s.getSpans(paraStart, paraEnd, EnrichedInputAlignmentSpan::class.java)

    if (spans.isEmpty()) return

    val dominantCss = spans.first().cssValue
    // Remove and trim all existing alignment spans that overlap this paragraph.
    for (span in spans) {
      val sStart = s.getSpanStart(span)
      val sEnd = s.getSpanEnd(span)
      val cssValue = span.cssValue

      s.removeSpan(span)

      // This ensures top fragments always end before the '\n' character, not at the paraStart
      if (sStart < paraStart) {
        val topEnd = if (paraStart > 0 && s[paraStart - 1] == '\n') paraStart - 1 else paraStart
        if (sStart < topEnd) {
          setAlignmentSpan(s, cssValue, sStart, topEnd)
        }
      }
      // This ensures bottom fragments always begin at the first character of the next paragraph, not on the '\n'  character
      if (sEnd > paraEnd) {
        val bottomStart = if (paraEnd < s.length && s[paraEnd] == '\n') paraEnd + 1 else paraEnd
        if (bottomStart < sEnd) {
          setAlignmentSpan(s, cssValue, bottomStart, sEnd)
        }
      }
    }

    // Re-apply a single span for the current paragraph with exact bounds.
    setAlignmentSpan(s, dominantCss, paraStart, paraEnd)
  }

  fun setAlignment(alignment: String) {
    val spannable = view.text as? SpannableStringBuilder ?: return
    val selection = view.selection ?: return

    val (rawStart, rawEnd) = selection.getParagraphSelection()
    val (start, end) = expandRangeToContiguousList(spannable, rawStart, rawEnd)
    val cssValue = toCssValue(alignment)

    var shiftedEnd = end
    var cursor = start

    while (cursor <= shiftedEnd) {
      val (paraStart, paraEnd) = spannable.getParagraphBounds(cursor)

      cleanUpExistingSpans(spannable, paraStart, paraEnd)

      if (cssValue != "auto") {
        if (paraStart == paraEnd) {
          // Empty paragraph: anchor alignment with a ZWS so the cursor sits inside the span.
          spannable.safelyInsertZWS(paraStart)
          setAlignmentSpan(spannable, cssValue, paraStart, paraStart + 1)

          shiftedEnd++
          if (paraStart + 1 >= shiftedEnd) break
          cursor = paraStart + 2
          continue
        } else {
          val wasInserted = spannable.safelyInsertZWS(paraStart)
          val shift = if (wasInserted) 1 else 0
          setAlignmentSpan(spannable, cssValue, paraStart, paraEnd + shift)
          if (wasInserted) shiftedEnd++
        }
      }

      if (paraEnd >= shiftedEnd || paraEnd == spannable.length) break
      cursor = paraEnd + 1
    }
  }

  fun getCurrentAlignment(): String {
    val spannable = view.text as? Spannable ?: return "auto"
    val selection = view.selection ?: return "auto"

    val cursorPos = selection.start.coerceAtLeast(0).coerceAtMost(spannable.length)
    val (paraStart, paraEnd) = spannable.getParagraphBounds(cursorPos)
    val spans = spannable.getSpans(paraStart, paraEnd, EnrichedInputAlignmentSpan::class.java)

    return spans.firstOrNull()?.cssValue ?: "auto"
  }

  private fun handleZwsBackspace(
    s: Editable,
    cursorPosition: Int,
  ): Int {
    if (cursorPosition > 0 && s[cursorPosition - 1] == '\n') {
      val (currentParaStart, currentParaEnd) = s.getParagraphBounds(cursorPosition)
      s
        .getSpans(currentParaStart, currentParaEnd, EnrichedInputAlignmentSpan::class.java)
        .forEach { s.removeSpan(it) }
      s.delete(cursorPosition - 1, cursorPosition)
      view.setSelection(cursorPosition - 1)
      return cursorPosition - 1
    } else if (cursorPosition == 0) {
      val (paraStart, paraEnd) = s.getParagraphBounds(0)
      s
        .getSpans(paraStart, paraEnd, EnrichedInputAlignmentSpan::class.java)
        .forEach { s.removeSpan(it) }
      return 0
    }
    return cursorPosition
  }

  private fun handleParagraphMerge(
    s: Editable,
    cursorPosition: Int,
  ): Int {
    val (paraStart, paraEnd) = s.getParagraphBounds(cursorPosition)
    val spans = s.getSpans(paraStart, paraEnd, EnrichedInputAlignmentSpan::class.java)
    var dominantTopSpan: EnrichedInputAlignmentSpan? = null

    spans.forEach { span ->
      if (s.getSpanStart(span) >= cursorPosition) {
        s.removeSpan(span)
      } else {
        dominantTopSpan = span
      }
    }

    // INCLUSIVE_EXCLUSIVE is intentional here: autoStretchAlignmentSpan will convert
    // it to EXCLUSIVE_EXCLUSIVE once the merge is complete.
    val (safeStart, safeEnd) = s.getSafeSpanBoundaries(paraStart, paraEnd)
    dominantTopSpan?.let { s.setSpan(it, safeStart, safeEnd, Spannable.SPAN_INCLUSIVE_EXCLUSIVE) }
    return cursorPosition
  }

  private fun handleNewlineInheritance(
    s: Editable,
    cursorPosition: Int,
    isZwsInjected: Boolean,
  ): Int {
    val prevCharIndex = (if (isZwsInjected) cursorPosition - 2 else cursorPosition - 1) - 1
    if (prevCharIndex < 0) return cursorPosition

    val (prevParaStart, prevParaEnd) = s.getParagraphBounds(prevCharIndex)
    val prevSpan =
      s
        .getSpans(prevParaStart, prevParaEnd, EnrichedInputAlignmentSpan::class.java)
        .firstOrNull() ?: return cursorPosition

    val (newParaStart, newParaEnd) = s.getParagraphBounds(cursorPosition)

    return if (newParaStart == newParaEnd) {
      (s as SpannableStringBuilder).safelyInsertZWS(cursorPosition)
      setAlignmentSpan(s, prevSpan.cssValue, cursorPosition, cursorPosition + 1)
      cursorPosition + 1
    } else {
      (s as SpannableStringBuilder).safelyInsertZWS(newParaStart)
      setAlignmentSpan(s, prevSpan.cssValue, newParaStart, newParaEnd + 1)
      cursorPosition + 1
    }
  }

  /**
   * Removes all alignment spans that overlap [paraStart, paraEnd], trimming any span
   * that extends beyond the paragraph rather than deleting it entirely.
   */
  private fun cleanUpExistingSpans(
    spannable: SpannableStringBuilder,
    paraStart: Int,
    paraEnd: Int,
  ) {
    val existing = spannable.getSpans(paraStart, paraEnd, EnrichedInputAlignmentSpan::class.java)
    for (span in existing) {
      val sStart = spannable.getSpanStart(span)
      val sEnd = spannable.getSpanEnd(span)
      spannable.removeSpan(span)

      // This ensures top fragments always end before the '\n' character, not at the paraStart
      if (sStart < paraStart) {
        val topEnd = if (paraStart > 0 && spannable[paraStart - 1] == '\n') paraStart - 1 else paraStart
        if (sStart < topEnd) {
          setAlignmentSpan(spannable, span.cssValue, sStart, topEnd)
        }
      }
      // This ensures bottom fragments always begin at the first character of the next paragraph, not on the '\n'  character
      if (sEnd > paraEnd) {
        val bottomStart = if (paraEnd < spannable.length && spannable[paraEnd] == '\n') paraEnd + 1 else paraEnd
        if (bottomStart < sEnd) {
          setAlignmentSpan(spannable, span.cssValue, bottomStart, sEnd)
        }
      }
    }
  }
}
