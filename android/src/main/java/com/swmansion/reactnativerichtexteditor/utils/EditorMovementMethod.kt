package com.swmansion.reactnativerichtexteditor.utils

import android.text.Selection
import android.text.Spannable
import android.text.method.ArrowKeyMovementMethod
import android.text.method.MovementMethod
import android.text.style.ClickableSpan
import android.view.MotionEvent
import android.widget.TextView

class EditorMovementMethod : ArrowKeyMovementMethod() {
  override fun onTouchEvent(widget: TextView, buffer: Spannable, event: MotionEvent): Boolean {
    val action = event.action

    if (action == MotionEvent.ACTION_UP ||
      action == MotionEvent.ACTION_DOWN
    ) {
      var x = event.x.toInt()
      var y = event.y.toInt()

      x -= widget.totalPaddingLeft
      y -= widget.totalPaddingTop

      x += widget.scrollX
      y += widget.scrollY

      val layout = widget.layout
      val line = layout.getLineForVertical(y)
      val off = layout.getOffsetForHorizontal(line, x.toFloat())

      val link = buffer.getSpans<ClickableSpan?>(off, off, ClickableSpan::class.java)

      if (link.size != 0) {
        if (action == MotionEvent.ACTION_UP) {
          link[0]!!.onClick(widget)
        } else {
          Selection.setSelection(buffer, buffer.getSpanStart(link[0]), buffer.getSpanEnd(link[0]))
        }

        return true
      }
    }

    return super.onTouchEvent(widget, buffer, event)
  }

  companion object {
    private var sInstance: EditorMovementMethod? = null

    val instance: MovementMethod
      get() {
        if (sInstance == null) {
          sInstance = EditorMovementMethod()
        }
        return sInstance!!
      }
  }
}
