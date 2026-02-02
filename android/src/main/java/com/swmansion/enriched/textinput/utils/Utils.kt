package com.swmansion.enriched.textinput.utils

import android.annotation.SuppressLint
import android.text.Selection
import android.text.Spannable
import android.text.Spanned
import android.util.Log
import android.view.MotionEvent
import android.widget.TextView
import com.swmansion.enriched.textinput.spans.EnrichedInputCheckboxListSpan
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

// Sets a touch listener on TextView which is responsible for detecting touches on checkbox icons
// We don't use ClickableSpan because it works fine only when LinkMovementMethod is set on TextView
// Which breaks text selection and other features
@SuppressLint("ClickableViewAccessibility")
fun TextView.setCheckboxClickListener() {
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
    val spans = spannable.getSpans(lineStart, lineStart, EnrichedInputCheckboxListSpan::class.java)
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

            // For focused input, ensure cursor is active for affected paragraph
            if (tv.isFocused) {
              val currentCursor = Selection.getSelectionEnd(spannable)
              if (currentCursor < start || currentCursor > end) {
                Selection.setSelection(spannable, end)
              }
            }
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
