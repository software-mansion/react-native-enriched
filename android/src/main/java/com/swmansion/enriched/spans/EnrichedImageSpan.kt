package com.swmansion.enriched.spans

import android.content.res.Resources
import android.graphics.BitmapFactory
import android.graphics.Canvas
import android.graphics.Color
import android.graphics.Paint
import android.graphics.drawable.BitmapDrawable
import android.graphics.drawable.Drawable
import android.text.Editable
import android.text.Spannable
import android.text.style.ImageSpan
import android.util.Log
import androidx.core.graphics.withSave
import com.swmansion.enriched.spans.interfaces.EnrichedInlineSpan
import com.swmansion.enriched.utils.AsyncDrawable
import androidx.core.graphics.drawable.toDrawable
import com.swmansion.enriched.utils.ForceRedrawSpan

fun prepareDrawableForImage(src: String): Drawable {
  var cleanPath = src

  if (cleanPath.startsWith("http://") || cleanPath.startsWith("https://")) {
    return AsyncDrawable(cleanPath)
  }

  if (cleanPath.startsWith("file://")) {
    cleanPath = cleanPath.substring(7)
  }

  var drawable: BitmapDrawable? = null

  try {
    val bitmap = BitmapFactory.decodeFile(cleanPath)
    if (bitmap != null) {
      drawable = bitmap.toDrawable(Resources.getSystem())
      // set bounds so it knows how big it is naturally,
      // though EnrichedImageSpan will override this with the HTML width/height later.
      drawable.setBounds(0, 0, bitmap.getWidth(), bitmap.getHeight())
    }
  } catch (e: Exception) {
    // Failed to load file
    Log.e("EnrichedParser", "Failed to load image from path: $cleanPath", e)
  }

  if (drawable != null) {
    return drawable
  }

  return Color.TRANSPARENT.toDrawable()
}

class EnrichedImageSpan : ImageSpan, EnrichedInlineSpan {
  private var width: Int = 0
  private var height: Int = 0

  constructor(source: String, width: Int, height: Int) : super(prepareDrawableForImage(source), source, ALIGN_BASELINE) {
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

  fun observeAsyncDrawableLoaded(text: Editable?) {
    val d = drawable

    if (d !is AsyncDrawable) {
      return
    }

    registerDrawableLoadCallback(d, text)

    // If it's already loaded (race condition), run logic immediately
    if (d.isLoaded) {
      d.onLoaded?.invoke()
    }
  }

  private fun registerDrawableLoadCallback (d: AsyncDrawable, text: Editable?) {
    d.onLoaded = onLoaded@{
      val text = text as? Spannable

      if (text == null) {
        return@onLoaded
      }

      val start = text.getSpanStart(this@EnrichedImageSpan)
      val end = text.getSpanEnd(this@EnrichedImageSpan)

      if (start != -1 && end != -1) {
        // trick for adding empty span to force redraw when image is loaded
        val redrawSpan = ForceRedrawSpan()
        text.setSpan(redrawSpan, start, end, Spannable.SPAN_INCLUSIVE_EXCLUSIVE)
        text.removeSpan(redrawSpan)
      }
    }
  }

  fun getWidth(): Int {
    return width
  }

  fun getHeight(): Int {
    return height
  }
}
