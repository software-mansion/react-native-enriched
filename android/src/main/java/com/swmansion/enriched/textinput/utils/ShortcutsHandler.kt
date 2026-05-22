package com.swmansion.enriched.textinput.utils

import android.text.Editable
import com.swmansion.enriched.common.EnrichedConstants
import com.swmansion.enriched.textinput.EnrichedTextInputView

class ShortcutsHandler(
  private val view: EnrichedTextInputView,
) {
  fun afterTextChanged(
    s: Editable,
    endCursorPosition: Int,
    previousTextLength: Int,
  ) {
    handleConfigurableShortcuts(s, endCursorPosition, previousTextLength)
    handleInlineShortcuts(s, endCursorPosition, previousTextLength)
  }

  private fun handleConfigurableShortcuts(
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

    for ((trigger, styleName, type) in shortcuts) {
      if (type == "inline") continue
      if (trigger.isEmpty()) continue
      if (!paragraphText.startsWith(trigger)) continue

      val resolvedStyle = resolveStyleName(styleName) ?: continue

      s.replace(start, start + trigger.length, "")
      view.toggleStyle(resolvedStyle)
      return
    }
  }

  private fun inlineShortcutsSorted(): List<Triple<String, String, String>> =
    view.textShortcuts
      .filter { (trigger, _, type) -> type == "inline" && trigger.isNotEmpty() }
      .sortedByDescending { it.first.length }

  private fun isDelimiterPartOfLongerInlineTrigger(
    trigger: String,
    delimStart: Int,
    text: String,
    inlineShortcuts: List<Triple<String, String, String>>,
    isOpening: Boolean,
  ): Boolean {
    val delimEnd = delimStart + trigger.length

    for ((longerTrigger, _, _) in inlineShortcuts) {
      if (longerTrigger.length <= trigger.length) continue

      val longerStart =
        when {
          isOpening -> {
            if (!longerTrigger.endsWith(trigger)) continue
            delimEnd - longerTrigger.length
          }

          longerTrigger.startsWith(trigger) -> {
            delimStart
          }

          longerTrigger.endsWith(trigger) -> {
            delimStart - (longerTrigger.length - trigger.length)
          }

          else -> {
            continue
          }
        }

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

    for ((trigger, styleName, _) in inlineShortcuts) {
      val resolvedStyle = resolveStyleName(styleName) ?: continue

      if (cursorPosition < trigger.length) continue
      val closingDelim = text.substring(cursorPosition - trigger.length, cursorPosition)
      if (closingDelim != trigger) continue

      val closeDelimStart = cursorPosition - trigger.length

      if (isDelimiterPartOfLongerInlineTrigger(trigger, closeDelimStart, text, inlineShortcuts, isOpening = false)) {
        continue
      }

      val searchText = text.substring(paraStart, closeDelimStart)
      val openIdx = searchText.lastIndexOf(trigger)
      if (openIdx < 0) continue

      val openAbsolute = paraStart + openIdx

      if (isDelimiterPartOfLongerInlineTrigger(trigger, openAbsolute, text, inlineShortcuts, isOpening = true)) {
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
