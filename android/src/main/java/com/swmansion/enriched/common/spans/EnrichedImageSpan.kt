package com.swmansion.enriched.common.spans

import android.content.res.Resources
import android.graphics.BitmapFactory
import android.graphics.Canvas
import android.graphics.ImageDecoder
import android.graphics.Paint
import android.graphics.drawable.AnimatedImageDrawable
import android.graphics.drawable.Drawable
import android.os.Build
import android.text.Editable
import android.text.Spannable
import android.text.style.ImageSpan
import android.util.Log
import androidx.core.graphics.drawable.toDrawable
import androidx.core.graphics.withSave
import com.swmansion.enriched.R
import com.swmansion.enriched.common.AsyncDrawable
import com.swmansion.enriched.common.ForceRedrawSpan
import com.swmansion.enriched.common.ResourceManager
import com.swmansion.enriched.common.spans.interfaces.EnrichedInlineSpan
import java.io.File

open class EnrichedImageSpan :
  ImageSpan,
  EnrichedInlineSpan {
  private var width: Int = 0
  private var height: Int = 0

  constructor(drawable: Drawable, source: String, width: Int, height: Int) : super(drawable, source, ALIGN_BASELINE) {
    this.width = width
    this.height = height
  }

  override fun draw(
    canvas: Canvas,
    text: CharSequence?,
    start: Int,
    end: Int,
    x: Float,
    top: Int,
    y: Int,
    bottom: Int,
    paint: Paint,
  ) {
    val drawable = drawable
    canvas.withSave {
      val transY = bottom - drawable.bounds.bottom - paint.fontMetricsInt.descent
      translate(x, transY.toFloat())
      drawable.draw(this)
    }
  }

  override fun getDrawable(): Drawable {
    val drawable = super.getDrawable()
    val scale = Resources.getSystem().displayMetrics.density

    drawable.setBounds(0, 0, (width * scale).toInt(), (height * scale).toInt())
    return drawable
  }

  override fun getSize(
    paint: Paint,
    text: CharSequence?,
    start: Int,
    end: Int,
    fm: Paint.FontMetricsInt?,
  ): Int {
    val d = drawable
    val rect = d.bounds

    if (fm != null) {
      val imageHeight = rect.bottom - rect.top

      // We want the image bottom to sit on the baseline (0).
      // Therefore, the image top will be at: -imageHeight.
      val targetTop = -imageHeight

      // Expand the line UPWARDS if the image is taller than the current font
      if (targetTop < fm.ascent) {
        fm.ascent = targetTop
        fm.top = targetTop
      }
    }

    return rect.right
  }

  private fun registerDrawableLoadCallback(
    d: AsyncDrawable,
    text: Editable?,
  ) {
    d.onLoaded = onLoaded@{
      val spannable = text as? Spannable

      if (spannable == null) {
        return@onLoaded
      }

      val start = spannable.getSpanStart(this@EnrichedImageSpan)
      val end = spannable.getSpanEnd(this@EnrichedImageSpan)

      if (start != -1 && end != -1) {
        // trick for adding empty span to force redraw when image is loaded
        val redrawSpan = ForceRedrawSpan()
        spannable.setSpan(redrawSpan, start, end, Spannable.SPAN_EXCLUSIVE_EXCLUSIVE)
        spannable.removeSpan(redrawSpan)
      }
    }
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

  fun getWidth(): Int = width

  fun getHeight(): Int = height

  companion object {
    fun prepareDrawableForImage(
      src: String,
      width: Int,
      height: Int,
    ): Drawable? {
      var cleanPath = src

      if (cleanPath.startsWith("http://") || cleanPath.startsWith("https://")) {
        return AsyncDrawable(cleanPath)
      }

      if (cleanPath.startsWith("file://")) {
        cleanPath = cleanPath.substring(7)
      }

      if (Build.VERSION.SDK_INT < Build.VERSION_CODES.P) {
        return try {
          val bitmap = BitmapFactory.decodeFile(cleanPath) ?: return null
          val drawable = bitmap.toDrawable(Resources.getSystem())
          drawable.setBounds(0, 0, bitmap.width, bitmap.height)
          return drawable
        } catch (e: Exception) {
          Log.e("EnrichedImageSpan", "Failed to load legacy image: $cleanPath", e)
          null
        }
      }

      return try {
        val file = File(cleanPath)
        val source = ImageDecoder.createSource(file)

        val density = Resources.getSystem().displayMetrics.density
        val targetWidthPx = (width * density).toInt()
        val targetHeightPx = (height * density).toInt()

        val drawable =
          ImageDecoder.decodeDrawable(source) { decoder, info, source ->
            decoder.setTargetSize(targetWidthPx, targetHeightPx)
          }

        if (drawable is AnimatedImageDrawable) {
          drawable.setBounds(0, 0, drawable.intrinsicWidth, drawable.intrinsicHeight)
          drawable.repeatCount = AnimatedImageDrawable.REPEAT_INFINITE
          drawable.start()
        }
        drawable
      } catch (e: Exception) {
        Log.e("EnrichedImageSpan", "Failed to load image: $cleanPath", e)
        null
      }
    }
  }
}
