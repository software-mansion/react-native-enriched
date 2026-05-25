package com.swmansion.enriched.textinput.utils

import android.text.Spannable
import com.swmansion.enriched.textinput.spans.EnrichedSpans
import com.swmansion.enriched.textinput.styles.HtmlStyle

fun resolveStyleName(name: String): String? =
  when (name) {
    "h1" -> EnrichedSpans.H1
    "h2" -> EnrichedSpans.H2
    "h3" -> EnrichedSpans.H3
    "h4" -> EnrichedSpans.H4
    "h5" -> EnrichedSpans.H5
    "h6" -> EnrichedSpans.H6
    "blockquote" -> EnrichedSpans.BLOCK_QUOTE
    "codeblock" -> EnrichedSpans.CODE_BLOCK
    "unordered_list" -> EnrichedSpans.UNORDERED_LIST
    "ordered_list" -> EnrichedSpans.ORDERED_LIST
    "checkbox_list" -> EnrichedSpans.CHECKBOX_LIST
    "bold" -> EnrichedSpans.BOLD
    "italic" -> EnrichedSpans.ITALIC
    "underline" -> EnrichedSpans.UNDERLINE
    "strikethrough" -> EnrichedSpans.STRIKETHROUGH
    "inline_code" -> EnrichedSpans.INLINE_CODE
    else -> null
  }

fun isInlineShortcutStyle(styleName: String): Boolean {
  val resolvedStyle = resolveStyleName(styleName) ?: return false
  return EnrichedSpans.inlineSpans.containsKey(resolvedStyle)
}

fun isStyleBlockedOnRange(
  styleName: String,
  start: Int,
  end: Int,
  spannable: Spannable,
  htmlStyle: HtmlStyle,
): Boolean {
  val mergingConfig =
    EnrichedSpans.getMergingConfigForStyle(styleName, htmlStyle) ?: return false

  for (blockingStyleName in mergingConfig.blockingStyles) {
    val spanClass = EnrichedSpans.allSpans[blockingStyleName]?.clazz ?: continue
    if (spannable.getSpans(start, end, spanClass).isNotEmpty()) {
      return true
    }
  }

  return false
}
