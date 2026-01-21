package com.swmansion.enriched.textinput.styles

import android.text.Editable
import android.text.Spannable
import android.text.SpannableStringBuilder
import android.util.Log
import com.swmansion.enriched.textinput.EnrichedTextInputView
import com.swmansion.enriched.textinput.spans.EnrichedSpans
import com.swmansion.enriched.textinput.spans.interfaces.EnrichedSpan
import com.swmansion.enriched.textinput.utils.EnrichedConstants
import com.swmansion.enriched.textinput.utils.getParagraphBounds
import com.swmansion.enriched.textinput.utils.getSafeSpanBoundaries
import com.swmansion.enriched.textinput.utils.removeZWS

class ParagraphStyles(
  private val view: EnrichedTextInputView,
) {
  private fun <T> getPreviousParagraphSpan(
    spannable: Spannable,
    paragraphStart: Int,
    type: Class<T>,
  ): T? {
    if (paragraphStart <= 0) return null

    val (previousParagraphStart, previousParagraphEnd) = spannable.getParagraphBounds(paragraphStart - 1)
    val spans = spannable.getSpans(previousParagraphStart, previousParagraphEnd, type)

    // A paragraph implies a single cohesive style. having multiple spans of the
    // same type (e.g., two codeblock spans) in one paragraph is an invalid state in current library logic
    if (spans.size > 1) {
      Log.w("ParagraphStyles", "getPreviousParagraphSpan(): Found more than one span in the paragraph!")
    }

    if (spans.isNotEmpty()) {
      return spans.first()
    }

    return null
  }

  private fun <T> getNextParagraphSpan(
    spannable: Spannable,
    paragraphEnd: Int,
    type: Class<T>,
  ): T? {
    if (paragraphEnd >= spannable.length - 1) return null

    val (nextParagraphStart, nextParagraphEnd) = spannable.getParagraphBounds(paragraphEnd + 1)

    val spans = spannable.getSpans(nextParagraphStart, nextParagraphEnd, type)

    // A paragraph implies a single cohesive style. having multiple spans of the
    // same type (e.g., two codeblock spans) in one paragraph is an invalid state in current library logic
    if (spans.size > 1) {
      Log.w("ParagraphStyles", "getNextParagraphSpan(): Found more than one span in the paragraph!")
    }

    if (spans.isNotEmpty()) {
      return spans.first()
    }

    return null
  }

  /**
   * Applies a continuous span to the specified range.
   * If the new range touches existing continuous spans, they are coalesced into a single span
   */
  private fun <T> setContinuousSpan(
    spannable: Spannable,
    start: Int,
    end: Int,
    type: Class<T>,
  ) {
    val span = type.getDeclaredConstructor(HtmlStyle::class.java).newInstance(view.htmlStyle)
    val previousSpan = getPreviousParagraphSpan(spannable, start, type)
    val nextSpan = getNextParagraphSpan(spannable, end, type)
    var newStart = start
    var newEnd = end

    if (previousSpan != null) {
      newStart = spannable.getSpanStart(previousSpan)
      spannable.removeSpan(previousSpan)
    }

    if (nextSpan != null && start != end) {
      newEnd = spannable.getSpanEnd(nextSpan)
      spannable.removeSpan(nextSpan)
    }

    val (safeStart, safeEnd) = spannable.getSafeSpanBoundaries(newStart, newEnd)
    spannable.setSpan(span, safeStart, safeEnd, Spannable.SPAN_EXCLUSIVE_EXCLUSIVE)
  }

  private fun <T> setSpan(
    spannable: Spannable,
    type: Class<T>,
    start: Int,
    end: Int,
  ) {
    if (EnrichedSpans.isTypeContinuous(type)) {
      setContinuousSpan(spannable, start, end, type)
      return
    }

    val span = type.getDeclaredConstructor(HtmlStyle::class.java).newInstance(view.htmlStyle)
    val (safeStart, safeEnd) = spannable.getSafeSpanBoundaries(start, end)
    spannable.setSpan(span, safeStart, safeEnd, Spannable.SPAN_EXCLUSIVE_EXCLUSIVE)
  }

  private fun <T> removeSpansForRange(
    spannable: Spannable,
    start: Int,
    end: Int,
    clazz: Class<T>,
  ): Boolean {
    val ssb = spannable as SpannableStringBuilder
    var finalStart = start
    var finalEnd = end

    val spans = ssb.getSpans(start, end, clazz)
    if (spans.isEmpty()) return false

    for (span in spans) {
      finalStart = ssb.getSpanStart(span).coerceAtMost(finalStart)
      finalEnd = ssb.getSpanEnd(span).coerceAtLeast(finalEnd)

      ssb.removeSpan(span)
    }

    ssb.removeZWS(finalStart, finalEnd)

    return true
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

  private fun <T> isSpanEnabledInNextLine(
    spannable: Spannable,
    index: Int,
    type: Class<T>,
  ): Boolean {
    val selection = view.selection ?: return false
    if (index + 1 >= spannable.length) return false
    val (start, end) = selection.getParagraphSelection()

    val spans = spannable.getSpans(start, end, type)
    return spans.isNotEmpty()
  }

  private fun <T> mergeAdjacentStyleSpans(
    s: Editable,
    endCursorPosition: Int,
    type: Class<T>,
  ) {
    val (start, end) = s.getParagraphBounds(endCursorPosition)
    val currParagraphSpans = s.getSpans(start, end, type)

    if (currParagraphSpans.isEmpty()) {
      return
    }

    val currSpan = currParagraphSpans[0]
    val nextSpan = getNextParagraphSpan(s, end, type)

    if (nextSpan == null) {
      return
    }

    val newStart = s.getSpanStart(currSpan)
    val newEnd = s.getSpanEnd(nextSpan)

    s.removeSpan(nextSpan)
    s.removeSpan(currSpan)

    val (safeStart, safeEnd) = s.getSafeSpanBoundaries(newStart, newEnd)
    val span = type.getDeclaredConstructor(HtmlStyle::class.java).newInstance(view.htmlStyle)

    s.setSpan(span, safeStart, safeEnd, Spannable.SPAN_EXCLUSIVE_EXCLUSIVE)
  }

  private fun handleConflictsDuringNewlineDeletion(
    s: Editable,
    style: String,
    paragraphStart: Int,
    paragraphEnd: Int,
  ): Boolean {
    val spanState = view.spanState ?: return false
    val mergingConfig = EnrichedSpans.getMergingConfigForStyle(style, view.htmlStyle) ?: return false
    var isConflicting = false
    val stylesToCheck = mergingConfig.blockingStyles + mergingConfig.conflictingStyles

    for (styleToCheck in stylesToCheck) {
      val conflictingType = EnrichedSpans.allSpans[styleToCheck]?.clazz ?: continue

      val spans = s.getSpans(paragraphStart, paragraphEnd, conflictingType)
      if (spans.isEmpty()) {
        continue
      }
      isConflicting = true

      val isParagraphStyle = EnrichedSpans.paragraphSpans[styleToCheck] != null
      if (!isParagraphStyle) {
        continue
      }

      for (span in spans) {
        extendStyleOnWholeParagraph(s, span as EnrichedSpan, conflictingType, paragraphEnd)
      }
    }

    if (isConflicting) {
      val styleStart = spanState.getStart(style) ?: return false
      spanState.setStart(style, null)
      removeStyle(style, styleStart, paragraphEnd)
      return true
    }

    return false
  }

  private fun deleteConflictingAndBlockingStyles(
    s: Editable,
    style: String,
    paragraphStart: Int,
    paragraphEnd: Int,
  ) {
    val mergingConfig = EnrichedSpans.getMergingConfigForStyle(style, view.htmlStyle) ?: return
    val stylesToCheck = mergingConfig.blockingStyles + mergingConfig.conflictingStyles

    for (styleToCheck in stylesToCheck) {
      val conflictingType = EnrichedSpans.allSpans[styleToCheck]?.clazz ?: continue

      val spans = s.getSpans(paragraphStart, paragraphEnd, conflictingType)
      for (span in spans) {
        s.removeSpan(span)
      }
    }
  }

  private fun <T> extendStyleOnWholeParagraph(
    s: Editable,
    span: EnrichedSpan,
    type: Class<T>,
    paragraphEnd: Int,
  ) {
    val currStyleStart = s.getSpanStart(span)
    s.removeSpan(span)
    val (safeStart, safeEnd) = s.getSafeSpanBoundaries(currStyleStart, paragraphEnd)
    setSpan(s, type, safeStart, safeEnd)
  }

  fun afterTextChanged(
    s: Editable,
    endPosition: Int,
    previousTextLength: Int,
  ) {
    var endCursorPosition = endPosition
    val isBackspace = s.length < previousTextLength
    val isNewLine = endCursorPosition == 0 || (endCursorPosition > 0 && s[endCursorPosition - 1] == '\n')
    val spanState = view.spanState ?: return

    for ((style, config) in EnrichedSpans.paragraphSpans) {
      val styleStart = spanState.getStart(style)

      if (styleStart == null) {
        if (isBackspace) {
          val (start, end) = s.getParagraphBounds(endCursorPosition)
          val spans = s.getSpans(start, end, config.clazz)

          for (span in spans) {
            // handle conflicts when entering paragraph with some paragraph style applied
            deleteConflictingAndBlockingStyles(s, style, start, end)
            extendStyleOnWholeParagraph(s, span as EnrichedSpan, config.clazz, end)
          }
        }

        if (config.isContinuous) {
          mergeAdjacentStyleSpans(s, endCursorPosition, config.clazz)
        }
        continue
      }

      if (isNewLine) {
        if (!config.isContinuous) {
          spanState.setStart(style, null)
          continue
        }

        if (isBackspace) {
          endCursorPosition -= 1
          spanState.setStart(style, null)
        } else {
          s.insert(endCursorPosition, EnrichedConstants.ZWS_STRING)
          endCursorPosition += 1
        }
      }

      var (start, end) = s.getParagraphBounds(styleStart, endCursorPosition)

      // handle conflicts when deleting newline from paragraph style (going back to previous line)
      if (isBackspace && styleStart != start) {
        val isConflicting = handleConflictsDuringNewlineDeletion(s, style, start, end)
        if (isConflicting) {
          continue
        }
      }

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
    if (view.selection == null) return
    val spannable = view.text as SpannableStringBuilder
    val (start, end) = view.selection.getParagraphSelection()
    val config = EnrichedSpans.paragraphSpans[name] ?: return
    val type = config.clazz

    val styleStart = view.spanState?.getStart(name)

    if (styleStart != null) {
      view.spanState.setStart(name, null)
      removeSpansForRange(spannable, start, end, type)
      view.selection.validateStyles()

      return
    }

    if (start == end) {
      spannable.insert(start, EnrichedConstants.ZWS_STRING)
      setAndMergeSpans(spannable, type, start, end + 1)
      view.selection.validateStyles()

      return
    }

    var currentStart = start
    var currentEnd = currentStart
    val paragraphs = spannable.substring(start, end).split("\n")

    for (paragraph in paragraphs) {
      spannable.insert(currentStart, EnrichedConstants.ZWS_STRING)
      currentEnd = currentStart + paragraph.length + 1
      currentStart = currentEnd + 1
    }

    setAndMergeSpans(spannable, type, start, currentEnd)
    view.selection.validateStyles()
  }

  fun getStyleRange(): Pair<Int, Int> = view.selection?.getParagraphSelection() ?: Pair(0, 0)

  fun removeStyle(
    name: String,
    start: Int,
    end: Int,
  ): Boolean {
    val config = EnrichedSpans.paragraphSpans[name] ?: return false
    val spannable = view.text as Spannable
    return removeSpansForRange(spannable, start, end, config.clazz)
  }
}
