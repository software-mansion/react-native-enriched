package com.swmansion.enriched.spans

import android.content.Context
import android.content.res.Resources
import android.graphics.Canvas
import android.graphics.Paint
import android.graphics.drawable.Drawable
import android.net.Uri
import android.text.style.ImageSpan
import androidx.core.graphics.withSave
import com.swmansion.enriched.spans.interfaces.EnrichedInlineSpan

class EnrichedImageSpan : ImageSpan, EnrichedInlineSpan {
  private var width: Int = 0
  private var height: Int = 0

  constructor(context: Context, uri: Uri, width: Int, height: Int) : super(context, uri, ALIGN_BASELINE) {
    this.width = width
    this.height = height
  }

  constructor(drawable: Drawable, source: String, width: Int, height: Int) : super(drawable, source, ALIGN_BASELINE) {
    this.width = width
    this.height = height
  }

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
    val scale = Resources.getSystem().displayMetrics.density
    
    drawable.setBounds(0, 0, (width * scale).toInt() , (height * scale).toInt())
    return drawable
  }

  fun getWidth(): Int {
    return width
  }

  fun getHeight(): Int {
    return height
  }
}
