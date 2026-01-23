package com.swmansion.enriched.textinput.utils

import android.content.res.Resources
import android.graphics.BitmapFactory
import android.graphics.Canvas
import android.graphics.Color
import android.graphics.ColorFilter
import android.graphics.ImageDecoder
import android.graphics.PixelFormat
import android.graphics.drawable.AnimatedImageDrawable
import android.graphics.drawable.Drawable
import android.os.Build
import android.os.Handler
import android.os.Looper
import android.util.Log
import androidx.core.graphics.drawable.toDrawable
import com.swmansion.enriched.R
import com.swmansion.enriched.common.ResourceManager
import java.net.URL
import java.nio.ByteBuffer
import java.util.concurrent.Executors

class AsyncDrawable(
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
        val bytes = inputStream.readBytes()
        val d = prepareDrawable(bytes)

        // Switch to Main Thread to update UI
        mainHandler.post {
          if (d != null) {
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

  private fun prepareDrawable(bytes: ByteArray): Drawable? {
    if (Build.VERSION.SDK_INT >= Build.VERSION_CODES.P) {
      try {
        val buffer = ByteBuffer.wrap(bytes)
        val source = ImageDecoder.createSource(buffer)

        val drawable =
          ImageDecoder.decodeDrawable(source) { decoder, _, _ ->
            decoder.setTargetSize(bounds.width(), bounds.height())
          }

        if (drawable is AnimatedImageDrawable) {
          drawable.setBounds(0, 0, drawable.intrinsicWidth, drawable.intrinsicHeight)
          drawable.repeatCount = AnimatedImageDrawable.REPEAT_INFINITE
          drawable.start()
        }

        return drawable
      } catch (e: Exception) {
        Log.w("AsyncDrawable", "ImageDecoder failed, falling back to Bitmap", e)
      }
    }

    // Fallback to bitmap if ImageDecoder fails
    return try {
      val bitmap = BitmapFactory.decodeByteArray(bytes, 0, bytes.size)
      bitmap?.toDrawable(Resources.getSystem())
    } catch (_: Exception) {
      null
    }
  }

  private fun loadPlaceholderImage() {
    internalDrawable = ResourceManager.getDrawableResource(R.drawable.broken_image)
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
  override fun getOpacity(): Int = PixelFormat.TRANSLUCENT

  override fun setBounds(
    left: Int,
    top: Int,
    right: Int,
    bottom: Int,
  ) {
    super.setBounds(left, top, right, bottom)
    internalDrawable.setBounds(left, top, right, bottom)
  }

  var onLoaded: (() -> Unit)? = null
}
