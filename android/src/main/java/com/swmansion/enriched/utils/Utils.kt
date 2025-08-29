package com.swmansion.enriched.utils

import android.text.Spannable
import android.text.SpannableString
import android.text.SpannableStringBuilder
import android.util.Log
import com.swmansion.enriched.spans.interfaces.EditorBlockSpan
import com.swmansion.enriched.spans.interfaces.EditorParagraphSpan
import org.json.JSONObject

fun jsonStringToStringMap(json: String): Map<String, String> {
  val result = mutableMapOf<String, String>()
  try {
    val jsonObject = JSONObject(json)
    for (key in jsonObject.keys()) {
      val value = jsonObject.opt(key)
      if (value is String) {
        result[key] = value
      }
    }
  } catch (e: Exception) {
    Log.w("ReactNativeRichTextEditorView", "Failed to parse JSON string to Map: $json", e)
  }

  return result
}

fun Spannable.getSafeSpanBoundaries(start: Int, end: Int): Pair<Int, Int> {
  val safeStart = start.coerceAtMost(end).coerceAtLeast(0)
  val safeEnd = end.coerceAtLeast(start).coerceAtMost(this.length)

  return Pair(safeStart, safeEnd)
}

fun Spannable.getParagraphBounds(start: Int, end: Int): Pair<Int, Int> {
  var startPosition = start.coerceAtLeast(0).coerceAtMost(this.length)
  var endPosition = end.coerceAtLeast(0).coerceAtMost(this.length)

  // Find the start of the paragraph
  while (startPosition > 0 && this[startPosition - 1] != '\n') {
    startPosition--
  }

  // Find the end of the paragraph
  while (endPosition < this.length && this[endPosition] != '\n') {
    endPosition++
  }

  if (startPosition >= endPosition) {
    // If the start position is equal or greater than the end position, return the same position
    startPosition = endPosition
  }

  return Pair(startPosition, endPosition)
}

fun Spannable.getParagraphBounds(index: Int): Pair<Int, Int> {
  return this.getParagraphBounds(index, index)
}

fun Spannable.mergeSpannables(start: Int, end: Int, string: String): Spannable {
  return this.mergeSpannables(start, end, SpannableString(string))
}

fun Spannable.mergeSpannables(start: Int, end: Int, spannable: Spannable): Spannable {
  var finalStart = start
  var finalEnd = end

  val builder = SpannableStringBuilder(this)
  val startBlockSpans = spannable.getSpans(0, 0, EditorBlockSpan::class.java)
  val startParagraphSpans = spannable.getSpans(0, 0, EditorParagraphSpan::class.java)
  val endBlockSpans = spannable.getSpans(this.length, this.length, EditorBlockSpan::class.java)
  val endParagraphSpans = spannable.getSpans(this.length, this.length, EditorParagraphSpan::class.java)
  val (paragraphStart, paragraphEnd) = this.getParagraphBounds(start, end)
  val isNewLineStart = startBlockSpans.isNotEmpty() || startParagraphSpans.isNotEmpty()
  val isNewLineEnd = endBlockSpans.isNotEmpty() || endParagraphSpans.isNotEmpty()

  if (isNewLineStart && start != paragraphStart) {
    builder.insert(start, "\n")
    finalStart = start + 1
    finalEnd = end + 1
  }

  if (isNewLineEnd && end != paragraphEnd) {
    builder.insert(finalEnd, "\n")
  }

  builder.replace(finalStart, finalEnd, spannable)

  return builder
}
