package com.swmansion.enriched.utils

import android.annotation.SuppressLint
import android.content.res.Resources
import android.graphics.BitmapFactory
import android.graphics.Canvas
import android.graphics.Color
import android.graphics.ColorFilter
import android.graphics.PixelFormat
import android.graphics.drawable.Drawable
import android.os.Handler
import android.os.Looper
import android.util.Log
import androidx.core.graphics.drawable.DrawableCompat
import java.net.URL
import java.util.concurrent.Executors
import androidx.core.graphics.drawable.toDrawable

class AsyncDrawable (
  private val url: String,
) : Drawable() {
  private var internalDrawable: Drawable = Color.TRANSPARENT.toDrawable()
  private val mainHandler = Handler(Looper.getMainLooper())
  private val executor = Executors.newSingleThreadExecutor()
  var isLoaded = false

  init {
    internalDrawable.bounds = bounds

    load()
  }

  private fun load() {
    executor.execute {
      try {
        isLoaded = false
        val inputStream = URL(url).openStream()
        val bitmap = BitmapFactory.decodeStream(inputStream)

        // Switch to Main Thread to update UI
        mainHandler.post {
          if (bitmap != null) {
            val d = bitmap.toDrawable(Resources.getSystem())
            d.bounds = bounds
            internalDrawable = d
          } else {
            loadPlaceholderImage()
          }
        }
      } catch (e: Exception) {
        Log.e("AsyncDrawable", "Failed to load: $url", e)

        loadPlaceholderImage()
      } finally {
        isLoaded = true
        onLoaded?.invoke()
      }
    }
  }

  @SuppressLint("UseCompatLoadingForDrawables")
  private fun loadPlaceholderImage() {
    val systemIcon = Resources.getSystem().getDrawable(android.R.drawable.ic_menu_report_image)
    val errorDrawable = DrawableCompat.wrap(systemIcon.mutate())

    internalDrawable = errorDrawable
  }

  override fun draw(canvas: Canvas) {
    internalDrawable.draw(canvas)
  }

  override fun setAlpha(alpha: Int) {
    internalDrawable.alpha = alpha
  }

  override fun setColorFilter(colorFilter: ColorFilter?) {
    internalDrawable.colorFilter = colorFilter
  }

  @Deprecated("Deprecated in Java")
  override fun getOpacity(): Int {
    return PixelFormat.TRANSLUCENT
  }

  override fun setBounds(left: Int, top: Int, right: Int, bottom: Int) {
    super.setBounds(left, top, right, bottom)
    internalDrawable.setBounds(left, top, right, bottom)
  }

  var onLoaded: (() -> Unit)? = null
}
