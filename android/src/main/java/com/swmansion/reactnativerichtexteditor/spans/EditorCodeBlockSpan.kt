package com.swmansion.reactnativerichtexteditor.spans

import android.graphics.Canvas
import android.graphics.Color
import android.graphics.Paint
import android.graphics.RectF
import android.graphics.Typeface
import android.text.TextPaint
import android.text.style.CharacterStyle
import android.text.style.LineBackgroundSpan
import com.swmansion.reactnativerichtexteditor.spans.interfaces.EditorParagraphSpan

class EditorCodeBlockSpan : CharacterStyle(), LineBackgroundSpan, EditorParagraphSpan {
  private val radius = 8f
  private val typeface = Typeface.MONOSPACE
  private val backgroundColor = Color.argb(90, 250, 250, 250)

  override fun updateDrawState(paint: TextPaint?) {
    paint?.typeface = typeface
  }

  override fun drawBackground(
    canvas: Canvas,
    p: Paint,
    left: Int,
    right: Int,
    top: Int,
    baseline: Int,
    bottom: Int,
    text: CharSequence,
    start: Int,
    end: Int,
    lineNum: Int
  ) {
    val previousColor = p.color;
    p.color = backgroundColor;
    val rect = RectF(left.toFloat(), top.toFloat(), right.toFloat(), bottom.toFloat())
    canvas.drawRoundRect(rect, radius, radius, p);
    p.color = previousColor
  }
}
