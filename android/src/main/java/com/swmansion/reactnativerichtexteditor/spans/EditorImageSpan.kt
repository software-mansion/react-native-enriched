package com.swmansion.reactnativerichtexteditor.spans

import android.content.Context
import android.graphics.Canvas
import android.graphics.Paint
import android.graphics.drawable.Drawable
import android.net.Uri
import android.text.style.DynamicDrawableSpan
import android.text.style.ImageSpan
import androidx.core.graphics.withSave
import com.swmansion.reactnativerichtexteditor.spans.interfaces.EditorSpan

class EditorImageSpan : ImageSpan, EditorSpan {
  private val width = 160
  private val height = 160

  constructor(context: Context, uri: Uri) : super(context, uri, DynamicDrawableSpan.ALIGN_BASELINE)

  constructor(drawable: Drawable, source: String) : super(drawable, source, DynamicDrawableSpan.ALIGN_BASELINE)

  override fun draw(
    canvas: Canvas, text: CharSequence?, start: Int, end: Int, x: Float,
    top: Int, y: Int, bottom: Int, paint: Paint
  ) {
    val drawable = drawable
    canvas.withSave() {
      val transY = bottom - drawable.bounds.bottom - paint.fontMetricsInt.descent
      translate(x, transY.toFloat())
      drawable.draw(this)
    }
  }

  override fun getDrawable(): Drawable {
    val drawable = super.getDrawable()
    drawable.setBounds(0, 0, width, height)
    return drawable
  }
}
