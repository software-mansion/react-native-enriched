package com.swmansion.enriched.spans

import android.graphics.Canvas
import android.graphics.Paint
import android.graphics.RectF
import android.graphics.Typeface
import android.text.TextPaint
import android.text.style.CharacterStyle
import android.text.style.LineBackgroundSpan
import com.swmansion.enriched.spans.interfaces.EditorBlockSpan
import com.swmansion.enriched.styles.RichTextStyle

class EditorCodeBlockSpan(private val richTextStyle: RichTextStyle) : CharacterStyle(), LineBackgroundSpan, EditorBlockSpan {
  override fun updateDrawState(paint: TextPaint?) {
    paint?.typeface = Typeface.MONOSPACE
    paint?.color = richTextStyle.codeBlockColor
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
    val previousColor = p.color
    p.color = richTextStyle.codeBlockBackgroundColor
    val rect = RectF(left.toFloat(), top.toFloat(), right.toFloat(), bottom.toFloat())
    canvas.drawRoundRect(rect, richTextStyle.codeBlockRadius, richTextStyle.codeBlockRadius, p)
    p.color = previousColor
  }
}
