package com.swmansion.enriched.utils

import android.annotation.SuppressLint
import android.text.Spannable
import android.text.SpannableString
import android.text.SpannableStringBuilder
import android.text.Spanned
import android.util.Log
import android.view.MotionEvent
import android.widget.TextView
import com.swmansion.enriched.spans.EnrichedCheckboxListSpan
import com.swmansion.enriched.spans.interfaces.EnrichedBlockSpan
import com.swmansion.enriched.spans.interfaces.EnrichedParagraphSpan
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
    Log.w("ReactNativeEnrichedView", "Failed to parse JSON string to Map: $json", e)
  }

  return result
}

fun Spannable.getSafeSpanBoundaries(
  start: Int,
  end: Int,
): Pair<Int, Int> {
  val safeStart = start.coerceAtMost(end).coerceAtLeast(0)
  val safeEnd = end.coerceAtLeast(start).coerceAtMost(this.length)

  return Pair(safeStart, safeEnd)
}

fun Spannable.getParagraphBounds(
  start: Int,
  end: Int,
): Pair<Int, Int> {
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

fun Spannable.getParagraphBounds(index: Int): Pair<Int, Int> = this.getParagraphBounds(index, index)

fun Spannable.mergeSpannables(
  start: Int,
  end: Int,
  string: String,
): Spannable = this.mergeSpannables(start, end, SpannableString(string))

fun Spannable.mergeSpannables(
  start: Int,
  end: Int,
  spannable: Spannable,
): Spannable {
  var finalStart = start
  var finalEnd = end

  val builder = SpannableStringBuilder(this)
  val startBlockSpans = spannable.getSpans(0, 0, EnrichedBlockSpan::class.java)
  val startParagraphSpans = spannable.getSpans(0, 0, EnrichedParagraphSpan::class.java)
  val endBlockSpans = spannable.getSpans(this.length, this.length, EnrichedBlockSpan::class.java)
  val endParagraphSpans = spannable.getSpans(this.length, this.length, EnrichedParagraphSpan::class.java)
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

// Sets a touch listener on TextView which is responsible for detecting touches on checkbox icons
// We don't use ClickableSpan because it works fine only when LinkMovementMethod is set on TextView
// Which breaks text selection and other features
@SuppressLint("ClickableViewAccessibility")
fun TextView.setLeadingMarginCheckboxClickListener() {
  var isDownOnCheckbox = false

  setOnTouchListener { v, event ->
    val tv = v as TextView
    val layout = tv.layout ?: return@setOnTouchListener false
    val spannable = tv.text as? Spanned ?: return@setOnTouchListener false

    // Get touch coordinates relative to the text content
    val x = event.x.toInt() - tv.totalPaddingLeft + tv.scrollX
    val y = event.y.toInt() - tv.totalPaddingTop + tv.scrollY

    // Identify the line and whether it's the first line of the span
    val line = layout.getLineForVertical(y)
    val lineStart = layout.getLineStart(line)

    // Find spans for specific line
    val spans = spannable.getSpans(lineStart, lineStart, EnrichedCheckboxListSpan::class.java)
    if (spans.isEmpty()) return@setOnTouchListener false

    // There should be only one span per line as we don't support nested lists
    val span = spans[0]
    val isFirstLine = spannable.getSpanStart(span) == lineStart
    val marginWidth = span.getLeadingMargin(true)

    // Check if touch is on checkbox icon area (which is in the leading margin on the first line)
    val isInHotZone = isFirstLine && x in 0..marginWidth

    when (event.action) {
      MotionEvent.ACTION_DOWN -> {
        if (isInHotZone) {
          isDownOnCheckbox = true
          return@setOnTouchListener true
        }
      }

      MotionEvent.ACTION_UP -> {
        if (isDownOnCheckbox && isInHotZone) {
          val spannable = tv.text as? Spannable
          if (spannable != null) {
            val start = spannable.getSpanStart(span)
            val end = spannable.getSpanEnd(span)
            val flags = spannable.getSpanFlags(span)
            span.isChecked = !span.isChecked

            // Reapply span so changes are visible without need to redraw entire TextView
            spannable.removeSpan(span)
            spannable.setSpan(span, start, end, flags)
          }

          isDownOnCheckbox = false
          return@setOnTouchListener true
        }
        isDownOnCheckbox = false
      }

      MotionEvent.ACTION_CANCEL -> {
        isDownOnCheckbox = false
      }
    }

    // Let TextView handle other touches (e.g., for selection)
    false
  }
}
