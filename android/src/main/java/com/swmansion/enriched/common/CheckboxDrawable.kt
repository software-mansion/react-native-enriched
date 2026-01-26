package com.swmansion.enriched.common

import android.graphics.Canvas
import android.graphics.ColorFilter
import android.graphics.Paint
import android.graphics.Path
import android.graphics.PixelFormat
import android.graphics.PorterDuff
import android.graphics.PorterDuffXfermode
import android.graphics.drawable.Drawable

class CheckboxDrawable(
  private val size: Int,
  private var color: Int,
  private var isChecked: Boolean,
) : Drawable() {
  private val paint = Paint(Paint.ANTI_ALIAS_FLAG)
  private val path = Path()

  fun update(checked: Boolean) {
    this.isChecked = checked
    invalidateSelf()
  }

  override fun draw(canvas: Canvas) {
    val saveCount = canvas.saveLayer(0f, 0f, size.toFloat(), size.toFloat(), null)

    paint.color = color
    paint.style = Paint.Style.FILL

    // Full square background with transparent checkmark
    if (isChecked) {
      val cornerRadius = size * 0.15f
      canvas.drawRoundRect(0f, 0f, size.toFloat(), size.toFloat(), cornerRadius, cornerRadius, paint)

      paint.xfermode = PorterDuffXfermode(PorterDuff.Mode.XOR)
      paint.strokeWidth = size * 0.15f
      paint.style = Paint.Style.STROKE
      paint.strokeCap = Paint.Cap.ROUND
      paint.strokeJoin = Paint.Join.ROUND

      path.reset()
      path.moveTo(size * 0.25f, size * 0.5f)
      path.lineTo(size * 0.45f, size * 0.7f)
      path.lineTo(size * 0.75f, size * 0.3f)
      canvas.drawPath(path, paint)

      paint.xfermode = null
      canvas.restoreToCount(saveCount)
      return
    }

    // Border only square for unchecked state
    paint.style = Paint.Style.STROKE
    paint.strokeWidth = size * 0.1f
    val margin = paint.strokeWidth / 2f
    val cornerRadius = size * 0.15f
    canvas.drawRoundRect(
      margin,
      margin,
      size - margin,
      size - margin,
      cornerRadius,
      cornerRadius,
      paint,
    )

    canvas.restoreToCount(saveCount)
  }

  override fun setAlpha(alpha: Int) {
    paint.alpha = alpha
  }

  override fun setColorFilter(colorFilter: ColorFilter?) {
    paint.colorFilter = colorFilter
  }

  @Deprecated("Deprecated in Java")
  override fun getOpacity(): Int = PixelFormat.TRANSLUCENT
}
