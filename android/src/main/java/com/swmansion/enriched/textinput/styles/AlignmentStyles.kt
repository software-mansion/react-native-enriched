package com.swmansion.enriched.textinput.styles

import android.text.Editable
import android.text.Spannable
import android.text.SpannableStringBuilder
import com.swmansion.enriched.common.EnrichedConstants
import com.swmansion.enriched.textinput.EnrichedTextInputView
import com.swmansion.enriched.textinput.spans.EnrichedInputAlignmentSpan
import com.swmansion.enriched.textinput.utils.getParagraphBounds
import com.swmansion.enriched.textinput.utils.getSafeSpanBoundaries

class AlignmentStyles(
  private val view: EnrichedTextInputView,
) {
  private fun toCssValue(alignment: String): String? =
    when (alignment) {
      "center" -> "center"
      "right" -> "right"
      "left" -> "left"
      else -> null
    }

  // MARK: - Text Watcher Entry Point

  fun afterTextChanged(
    s: Editable,
    cursorPosition: Int,
    deletedText: String,
  ) {
    if (s.isEmpty()) {
      handleEmptyDocumentReset(s)
      return
    }

    val isNewLineInserted = cursorPosition > 0 && cursorPosition <= s.length && s[cursorPosition - 1] == '\n' && deletedText.isEmpty()
    val includesNewlineDeletion = deletedText.contains('\n')
    val isZwsDeleted = deletedText == EnrichedConstants.ZWS_STRING

    view.runAsATransaction {
      if (isZwsDeleted) {
        handleZwsBackspace(s, cursorPosition)
      } else if (includesNewlineDeletion) {
        handleParagraphMerge(s, cursorPosition)
      } else if (isNewLineInserted) {
        handleNewlineInheritance(s, cursorPosition)
      }
    }

    view.selection?.validateStyles()
  }

  // MARK: - Alignment Toolbar Actions

  fun setAlignment(alignment: String) {
    val spannable = view.text as? SpannableStringBuilder ?: return
    val selection = view.selection ?: return

    val (start, end) = selection.getParagraphSelection()
    val cssValue = toCssValue(alignment)

    var shiftedEnd = end
    var cursor = start

    while (cursor <= shiftedEnd) {
      val (paraStart, paraEnd) = spannable.getParagraphBounds(cursor)

      cleanUpExistingSpans(spannable, paraStart, paraEnd)

      if (cssValue != null) {
        if (paraStart == paraEnd) {
          // Empty line: Insert ZWS anchor
          spannable.insert(paraStart, EnrichedConstants.ZWS_STRING)
          spannable.setSpan(
            EnrichedInputAlignmentSpan(cssValue),
            paraStart,
            paraStart + 1,
            Spannable.SPAN_INCLUSIVE_EXCLUSIVE,
          )

          shiftedEnd++ // Document grew, expand loop boundary

          if (paraStart + 1 >= shiftedEnd) break
          cursor = paraStart + 2
          continue
        } else {
          // Standard text paragraph
          val (safeStart, safeEnd) = spannable.getSafeSpanBoundaries(paraStart, paraEnd)
          if (safeStart < safeEnd) {
            spannable.setSpan(
              EnrichedInputAlignmentSpan(cssValue),
              safeStart,
              safeEnd,
              Spannable.SPAN_INCLUSIVE_EXCLUSIVE,
            )
          }
        }
      }

      if (paraEnd >= shiftedEnd || paraEnd == spannable.length) break
      cursor = paraEnd + 1
    }

    // Nudge the cursor to force Android to redraw it at the new aligned position
    view.setSelection(view.selection.start, view.selection.end)
  }

  fun getCurrentAlignment(): String {
    val spannable = view.text as? Spannable ?: return "left"
    val selection = view.selection ?: return "left"

    val cursorPos = selection.start.coerceAtLeast(0).coerceAtMost(spannable.length)
    val (paraStart, paraEnd) = spannable.getParagraphBounds(cursorPos)
    val spans = spannable.getSpans(paraStart, paraEnd, EnrichedInputAlignmentSpan::class.java)

    return spans.firstOrNull()?.cssValue ?: "left"
  }

  // MARK: - Private Handlers

  /**
   * Resets the entire input to the default state when all text is deleted.
   */
  private fun handleEmptyDocumentReset(s: Editable) {
    view.runAsATransaction {
      val spans = s.getSpans(0, 0, EnrichedInputAlignmentSpan::class.java)
      spans.forEach { s.removeSpan(it) }
      view.setSelection(0)
    }
    view.selection?.validateStyles()
  }

  /**
   * Handles backspacing a Zero Width Space. Deletes the preceding newline to merge upward,
   * or clears the alignment if at the very beginning of the document.
   */
  private fun handleZwsBackspace(
    s: Editable,
    cursorPosition: Int,
  ) {
    if (cursorPosition > 0 && s[cursorPosition - 1] == '\n') {
      // Clean up orphaned span from the bottom line before merging
      val (currentParaStart, currentParaEnd) = s.getParagraphBounds(cursorPosition)
      s
        .getSpans(currentParaStart, currentParaEnd, EnrichedInputAlignmentSpan::class.java)
        .forEach { s.removeSpan(it) }

      // Delete the newline to jump to the previous line
      s.delete(cursorPosition - 1, cursorPosition)
      view.setSelection(cursorPosition - 1)
    } else if (cursorPosition == 0) {
      // First line cleanup
      val (paraStart, paraEnd) = s.getParagraphBounds(0)
      s
        .getSpans(paraStart, paraEnd, EnrichedInputAlignmentSpan::class.java)
        .forEach { s.removeSpan(it) }
    }
  }

  /**
   * Resolves Conflicting Spans when paragraphs are merged manually by the user
   * (e.g., deleting a newline or deleting a highlighted block across paragraphs).
   */
  private fun handleParagraphMerge(
    s: Editable,
    cursorPosition: Int,
  ) {
    val (paraStart, paraEnd) = s.getParagraphBounds(cursorPosition)
    val spans = s.getSpans(paraStart, paraEnd, EnrichedInputAlignmentSpan::class.java)

    var dominantTopSpan: EnrichedInputAlignmentSpan? = null

    spans.forEach { span ->
      if (s.getSpanStart(span) >= cursorPosition) {
        // Orphan span from a pulled-up bottom paragraph. Kill it.
        s.removeSpan(span)
      } else {
        // This span belongs to the top paragraph.
        dominantTopSpan = span
      }
    }

    // Stretch the top paragraph's span to cover the newly merged text.
    dominantTopSpan?.let {
      s.setSpan(it, paraStart, paraEnd, Spannable.SPAN_INCLUSIVE_EXCLUSIVE)
    }
  }

  /**
   * Propagates the alignment of the previous paragraph to a newly created line.
   */
  private fun handleNewlineInheritance(
    s: Editable,
    cursorPosition: Int,
  ) {
    val (prevParaStart, prevParaEnd) = s.getParagraphBounds(cursorPosition - 1)
    val prevSpan =
      s
        .getSpans(prevParaStart, prevParaEnd, EnrichedInputAlignmentSpan::class.java)
        .firstOrNull() ?: return

    val (newParaStart, newParaEnd) = s.getParagraphBounds(cursorPosition)

    if (newParaStart == newParaEnd) {
      // Empty new line — insert ZWS anchor
      s.insert(cursorPosition, EnrichedConstants.ZWS_STRING)
      s.setSpan(
        EnrichedInputAlignmentSpan(prevSpan.cssValue),
        cursorPosition,
        cursorPosition + 1,
        Spannable.SPAN_INCLUSIVE_EXCLUSIVE,
      )
      view.setSelection(cursorPosition + 1)
    } else {
      // Cursor was moved mid-sentence and Enter was pressed
      s.setSpan(
        EnrichedInputAlignmentSpan(prevSpan.cssValue),
        newParaStart,
        newParaEnd,
        Spannable.SPAN_INCLUSIVE_EXCLUSIVE,
      )
    }
  }

  /**
   * Surgically removes spans from a specific paragraph bounds, splitting any global
   * spans that leaked outside the target paragraph.
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

      if (sStart < paraStart) {
        spannable.setSpan(EnrichedInputAlignmentSpan(span.cssValue), sStart, paraStart, Spannable.SPAN_INCLUSIVE_EXCLUSIVE)
      }
      if (sEnd > paraEnd) {
        spannable.setSpan(EnrichedInputAlignmentSpan(span.cssValue), paraEnd, sEnd, Spannable.SPAN_INCLUSIVE_EXCLUSIVE)
      }
    }
  }
}
