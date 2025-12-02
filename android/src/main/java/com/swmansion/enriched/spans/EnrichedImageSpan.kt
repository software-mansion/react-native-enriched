package com.swmansion.enriched.spans

import android.annotation.SuppressLint
import android.content.res.Resources
import android.graphics.BitmapFactory
import android.graphics.Canvas
import android.graphics.Color
import android.graphics.Paint
import android.graphics.drawable.BitmapDrawable
import android.graphics.drawable.Drawable
import android.text.Editable
import android.text.Spannable
import android.text.SpannableStringBuilder
import android.text.style.ImageSpan
import android.util.Log
import androidx.core.graphics.drawable.DrawableCompat
import androidx.core.graphics.drawable.toBitmap
import androidx.core.graphics.drawable.toBitmapOrNull
import androidx.core.graphics.withSave
import com.swmansion.enriched.spans.interfaces.EnrichedInlineSpan
import com.swmansion.enriched.utils.AsyncDrawable
import androidx.core.graphics.drawable.toDrawable
import com.swmansion.enriched.utils.ForceRedrawSpan

class EnrichedImageSpan : ImageSpan, EnrichedInlineSpan {
  private var width: Int = 0
  private var height: Int = 0

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

  override fun getSize(
    paint: Paint,
    text: CharSequence?,
    start: Int,
    end: Int,
    fm: Paint.FontMetricsInt?
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

  private fun registerDrawableLoadCallback (d: AsyncDrawable, text: Editable?) {
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
        spannable.setSpan(redrawSpan, start, end, Spannable.SPAN_INCLUSIVE_EXCLUSIVE)
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

  fun getWidth(): Int {
    return width
  }

  fun getHeight(): Int {
    return height
  }

  companion object {
    @SuppressLint("UseCompatLoadingForDrawables")
    fun createEnrichedImageSpan(src: String, width: Int, height: Int): EnrichedImageSpan {
      var imgDrawable = prepareDrawableForImage(src)

      if (imgDrawable == null) {
        val systemIcon = Resources.getSystem().getDrawable(android.R.drawable.ic_menu_report_image)
        imgDrawable = DrawableCompat.wrap(systemIcon.mutate())
      }

      return EnrichedImageSpan(imgDrawable, src, width, height)
    }

    private fun prepareDrawableForImage(src: String): Drawable? {
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

      return drawable
    }
  }
}
