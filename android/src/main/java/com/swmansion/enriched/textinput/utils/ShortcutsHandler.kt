package com.swmansion.enriched.textinput.utils

import android.text.Editable
import com.swmansion.enriched.common.EnrichedConstants
import com.swmansion.enriched.textinput.EnrichedTextInputView
import com.swmansion.enriched.textinput.spans.EnrichedSpans

class ShortcutsHandler(
  private val view: EnrichedTextInputView,
) {
  fun afterTextChanged(
    s: Editable,
    endCursorPosition: Int,
    previousTextLength: Int,
  ) {
    handleParagraphShortcuts(s, endCursorPosition, previousTextLength)
    handleInlineShortcuts(s, endCursorPosition, previousTextLength)
  }

  private fun handleParagraphShortcuts(
    s: Editable,
    endCursorPosition: Int,
    previousTextLength: Int,
  ) {
    val shortcuts = view.textShortcuts
    if (shortcuts.isEmpty()) return
    if (previousTextLength >= s.length) return

    val cursorPosition = endCursorPosition.coerceAtMost(s.length)
    val (start, end) = s.getParagraphBounds(cursorPosition)
    val paragraphText = s.substring(start, end)

    val effectiveTriggerStart =
      if (paragraphText.startsWith(EnrichedConstants.ZWS_STRING)) {
        if (paragraphHasNonAlignmentSpan(s, start, end)) return
        start + 1
      } else {
        start
      }

    for ((trigger, styleName) in shortcuts) {
      if (isInlineShortcutStyle(styleName)) continue
      if (trigger.isEmpty()) continue
      if (!s.substring(effectiveTriggerStart, end).startsWith(trigger)) continue

      val resolvedStyle = resolveStyleName(styleName) ?: continue

      s.replace(effectiveTriggerStart, effectiveTriggerStart + trigger.length, "")
      view.toggleStyle(resolvedStyle)
      return
    }
  }

  private fun paragraphHasNonAlignmentSpan(
    s: Editable,
    start: Int,
    end: Int,
  ): Boolean {
    val paragraphAndListClasses =
      (EnrichedSpans.paragraphSpans.values + EnrichedSpans.listSpans.values).map { it.clazz }
    return paragraphAndListClasses.any { clazz ->
      s.getSpans(start, end, clazz).isNotEmpty()
    }
  }

  private fun inlineShortcutsSorted(): List<Pair<String, String>> =
    view.textShortcuts
      .filter { (trigger, styleName) ->
        isInlineShortcutStyle(styleName) && trigger.isNotEmpty()
      }.sortedByDescending { it.first.length }

  // Delimiter at [delimStart] is part of a longer inline trigger (e.g. `*`
  // inside `**`).
  private fun isDelimiterPartOfLongerInlineTrigger(
    trigger: String,
    delimStart: Int,
    text: String,
    inlineShortcuts: List<Pair<String, String>>,
  ): Boolean {
    val delimEnd = delimStart + trigger.length

    for ((longerTrigger, _) in inlineShortcuts) {
      if (longerTrigger.length <= trigger.length) continue
      if (!longerTrigger.endsWith(trigger)) continue

      val longerStart = delimEnd - longerTrigger.length
      if (longerStart < 0 || longerStart + longerTrigger.length > text.length) continue

      if (text.substring(longerStart, longerStart + longerTrigger.length) == longerTrigger) {
        return true
      }
    }

    return false
  }

  private fun handleInlineShortcuts(
    s: Editable,
    endCursorPosition: Int,
    previousTextLength: Int,
  ) {
    val shortcuts = view.textShortcuts
    if (shortcuts.isEmpty()) return
    if (previousTextLength >= s.length) return

    val cursorPosition = endCursorPosition.coerceAtMost(s.length)
    val text = s.toString()
    val (paraStart, _) = s.getParagraphBounds(cursorPosition)
    val inlineShortcuts = inlineShortcutsSorted()

    for ((trigger, styleName) in inlineShortcuts) {
      val resolvedStyle = resolveStyleName(styleName) ?: continue

      if (cursorPosition < trigger.length) continue
      val closingDelim = text.substring(cursorPosition - trigger.length, cursorPosition)
      if (closingDelim != trigger) continue

      val closeDelimStart = cursorPosition - trigger.length

      val searchText = text.substring(paraStart, closeDelimStart)
      val openIdx = searchText.lastIndexOf(trigger)
      if (openIdx < 0) continue

      val openAbsolute = paraStart + openIdx

      if (isDelimiterPartOfLongerInlineTrigger(trigger, openAbsolute, text, inlineShortcuts)) {
        continue
      }

      val contentStart = openAbsolute + trigger.length
      val contentEnd = closeDelimStart
      if (contentEnd <= contentStart) continue

      if (isStyleBlockedOnRange(resolvedStyle, contentStart, contentEnd, s, view.htmlStyle)) {
        continue
      }

      s.delete(closeDelimStart, cursorPosition)
      s.delete(openAbsolute, openAbsolute + trigger.length)

      val adjustedStart = openAbsolute
      val adjustedEnd = contentEnd - trigger.length

      view.inlineStyles?.applyStyleOnRange(resolvedStyle, adjustedStart, adjustedEnd)
      view.setSelection(adjustedEnd, adjustedEnd)
      view.spanState?.setStart(resolvedStyle, null)
      return
    }
  }
}
