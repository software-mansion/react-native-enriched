package com.swmansion.enriched.text

import android.text.Selection
import android.text.Spannable
import android.text.method.LinkMovementMethod
import android.view.MotionEvent
import android.widget.TextView
import com.swmansion.enriched.text.spans.interfaces.EnrichedTextClickableSpan

class EnrichedTextMovementMethod : LinkMovementMethod() {
  override fun onTouchEvent(
    widget: TextView,
    buffer: Spannable,
    event: MotionEvent,
  ): Boolean {
    val action = event.action

    if (action == MotionEvent.ACTION_UP || action == MotionEvent.ACTION_DOWN || action == MotionEvent.ACTION_CANCEL) {
      val x = (event.x - widget.totalPaddingLeft + widget.scrollX).toInt()
      val y = (event.y - widget.totalPaddingTop + widget.scrollY).toInt()

      val layout = widget.layout
      val line = layout.getLineForVertical(y)
      val off = layout.getOffsetForHorizontal(line, x.toFloat())

      val links = buffer.getSpans(off, off, EnrichedTextClickableSpan::class.java)

      if (links.isNotEmpty()) {
        val link = links[0]

        when (action) {
          MotionEvent.ACTION_DOWN -> {
            link.isPressed = true
            Selection.setSelection(buffer, buffer.getSpanStart(link), buffer.getSpanEnd(link))
          }

          MotionEvent.ACTION_UP -> {
            link.onClick(widget)
            link.isPressed = false
            Selection.removeSelection(buffer)
          }

          MotionEvent.ACTION_CANCEL -> {
            link.isPressed = false
            Selection.removeSelection(buffer)
          }
        }

        widget.invalidate()
        return true
      } else {
        val allSpans = buffer.getSpans(0, buffer.length, EnrichedTextClickableSpan::class.java)
        allSpans.forEach { it.isPressed = false }
        Selection.removeSelection(buffer)
        widget.invalidate()
      }
    }
    return false
  }

  companion object {
    private var instance: EnrichedTextMovementMethod? = null

    fun getInstance(): EnrichedTextMovementMethod {
      if (instance == null) instance = EnrichedTextMovementMethod()
      return instance!!
    }
  }
}
