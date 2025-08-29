package com.swmansion.enriched.spans

import android.content.Context
import android.graphics.Canvas
import android.graphics.Paint
import android.graphics.drawable.Drawable
import android.net.Uri
import android.text.style.ImageSpan
import androidx.core.graphics.withSave
import com.swmansion.enriched.spans.interfaces.EditorInlineSpan
import com.swmansion.enriched.styles.RichTextStyle

class EditorImageSpan : ImageSpan, EditorInlineSpan {
  private var richTextStyle: RichTextStyle? = null

  constructor(context: Context, uri: Uri, richTextStyle: RichTextStyle, ) : super(context, uri, ALIGN_BASELINE) {
    this.richTextStyle = richTextStyle
  }

  constructor(drawable: Drawable, source: String, richTextStyle: RichTextStyle) : super(drawable, source, ALIGN_BASELINE) {
    this.richTextStyle = richTextStyle
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
    drawable.setBounds(0, 0, richTextStyle!!.imgWidth, richTextStyle!!.imgHeight)
    return drawable
  }
}
