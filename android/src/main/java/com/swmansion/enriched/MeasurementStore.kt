package com.swmansion.enriched

import android.graphics.Typeface
import android.graphics.text.LineBreaker
import android.os.Build
import android.text.Spannable
import android.text.StaticLayout
import android.text.TextPaint
import android.util.Log
import com.facebook.react.uimanager.PixelUtil
import com.facebook.yoga.YogaMeasureOutput
import java.util.concurrent.ConcurrentHashMap

object MeasurementStore {
  data class PaintParams(
    val typeface: Typeface,
    val fontSize: Float,
  )

  data class MeasurementParams(
    val cachedWidth: Float,
    val cachedSize: Long,

    val spannable: Spannable?,
    val paint: TextPaint,
  )

  private val data = ConcurrentHashMap<Int, MeasurementParams>()

  fun store(id: Int, spannable: Spannable?, paint: TextPaint): Boolean {
    val cachedWidth = data[id]?.cachedWidth ?: 0f
    val cachedSize = data[id]?.cachedSize ?: 0L
    val size = measure(cachedWidth, spannable, paint)
//    val paintParams = PaintParams(paint.typeface, paint.textSize)

    data[id] = MeasurementParams(cachedWidth, size, spannable, paint)
    return cachedSize != size
  }

  fun release(id: Int) {
    data.remove(id)
  }

  fun measure(maxWidth: Float, spannable: Spannable?, paintParams: PaintParams): Long {
    val paint = TextPaint().apply {
      typeface = paintParams.typeface
      textSize = paintParams.fontSize
    }

    return measure(maxWidth, spannable, paint)
  }

  fun measure(maxWidth: Float, spannable: Spannable?, paint: TextPaint): Long {
    val text = spannable ?: ""
    val textLength = text.length
    val builder = StaticLayout.Builder
      .obtain(text, 0, textLength, paint, maxWidth.toInt())
      .setIncludePad(true)
      .setLineSpacing(0f, 1f)

    if (Build.VERSION.SDK_INT >= Build.VERSION_CODES.Q) {
      builder.setBreakStrategy(LineBreaker.BREAK_STRATEGY_HIGH_QUALITY)
    }

    if (Build.VERSION.SDK_INT >= Build.VERSION_CODES.P) {
      builder.setUseLineSpacingFromFallbacks(true)
    }

    val staticLayout = builder.build()

    val heightInSP = PixelUtil.toDIPFromPixel(staticLayout.height.toFloat())
    val widthInSP = PixelUtil.toDIPFromPixel(maxWidth)
    return YogaMeasureOutput.make(widthInSP, heightInSP)
  }

  fun getMeasureById(id: Int?, width: Float): Long {
    val id = id ?: return YogaMeasureOutput.make(0, 0)
    val value = data[id] ?: return YogaMeasureOutput.make(0, 0)

    Log.d("MeasurementStore", "Retrieved measurement params for id: $id")
    Log.d("MeasurementStore", "Cached width: ${value.cachedWidth}, Cached size: ${value.cachedSize}, Spannable: ${value.spannable}")

    if (width == value.cachedWidth) {
      return value.cachedSize
    }

    val size = measure(width, value.spannable, value.paint)
    data[id] = MeasurementParams(width, size, value.spannable, value.paint)
    return size
  }
}
