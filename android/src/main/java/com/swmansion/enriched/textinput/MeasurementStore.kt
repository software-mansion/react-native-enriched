package com.swmansion.enriched.textinput

import android.content.Context
import android.graphics.Typeface
import android.graphics.text.LineBreaker
import android.os.Build
import android.text.Spannable
import android.text.StaticLayout
import android.text.TextPaint
import android.util.Log
import com.facebook.react.bridge.ReadableMap
import com.facebook.react.uimanager.PixelUtil
import com.facebook.react.views.text.ReactTypefaceUtils.applyStyles
import com.facebook.react.views.text.ReactTypefaceUtils.parseFontStyle
import com.facebook.react.views.text.ReactTypefaceUtils.parseFontWeight
import com.facebook.yoga.YogaMeasureMode
import com.facebook.yoga.YogaMeasureOutput
import com.swmansion.enriched.common.parser.EnrichedParser
import com.swmansion.enriched.textinput.styles.HtmlStyle
import java.util.concurrent.ConcurrentHashMap
import kotlin.math.ceil

object MeasurementStore {
  data class PaintParams(
    val typeface: Typeface,
    val fontSize: Float,
  )

  data class MeasurementParams(
    val initialized: Boolean,
    val cachedWidth: Float,
    val cachedSize: Long,
    val spannable: CharSequence?,
    val paintParams: PaintParams,
  )

  private val data = ConcurrentHashMap<Int, MeasurementParams>()

  fun store(
    id: Int,
    spannable: Spannable?,
    paint: TextPaint,
  ): Boolean {
    val cachedWidth = data[id]?.cachedWidth ?: 0f
    val cachedSize = data[id]?.cachedSize ?: 0L
    val initialized = data[id]?.initialized ?: true

    val size = measure(cachedWidth, spannable, paint)
    val paintParams = PaintParams(paint.typeface, paint.textSize)

    data[id] = MeasurementParams(initialized, cachedWidth, size, spannable, paintParams)
    return cachedSize != size
  }

  fun release(id: Int) {
    data.remove(id)
  }

  private fun measure(
    maxWidth: Float,
    spannable: CharSequence?,
    paintParams: PaintParams,
  ): Long {
    val paint =
      TextPaint().apply {
        typeface = paintParams.typeface
        textSize = paintParams.fontSize
      }

    return measure(maxWidth, spannable, paint)
  }

  private fun measure(
    maxWidth: Float,
    spannable: CharSequence?,
    paint: TextPaint,
  ): Long {
    val text = spannable ?: ""
    val textLength = text.length
    val builder =
      StaticLayout.Builder
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

  // Returns either: Spannable parsed from HTML defaultValue, or plain text defaultValue, or "I" if no defaultValue
  private fun getInitialText(
    defaultView: EnrichedTextInputView,
    props: ReadableMap?,
  ): CharSequence {
    val defaultValue = props?.getString("defaultValue")

    // If there is no default value, assume text is one line, "I" is a good approximation of height
    if (defaultValue == null) return "I"

    val isHtml = defaultValue.startsWith("<html>") && defaultValue.endsWith("</html>")
    if (!isHtml) return defaultValue

    try {
      val htmlStyle = HtmlStyle(defaultView, props.getMap("htmlStyle"))
      val factory = EnrichedTextInputSpannableFactory()
      val parsed = EnrichedParser.fromHtml(defaultValue, htmlStyle, factory)
      return parsed.trimEnd('\n')
    } catch (e: Exception) {
      Log.w("MeasurementStore", "Error parsing initial HTML text: ${e.message}")
      return defaultValue
    }
  }

  private fun getInitialFontSize(
    defaultView: EnrichedTextInputView,
    props: ReadableMap?,
  ): Float {
    val propsFontSize = props?.getDouble("fontSize")?.toFloat()
    if (propsFontSize == null) return defaultView.textSize

    return ceil(PixelUtil.toPixelFromSP(propsFontSize))
  }

  // Called when view measurements are not available in the store
  // Most likely first measurement, we can use defaultValue, as no native state is set yet
  private fun initialMeasure(
    context: Context,
    id: Int?,
    width: Float,
    props: ReadableMap?,
  ): Long {
    val defaultView = EnrichedTextInputView(context)

    val text = getInitialText(defaultView, props)
    val fontSize = getInitialFontSize(defaultView, props)

    val fontFamily = props?.getString("fontFamily")
    val fontStyle = parseFontStyle(props?.getString("fontStyle"))
    val fontWeight = parseFontWeight(props?.getString("fontWeight"))

    val typeface = applyStyles(defaultView.typeface, fontStyle, fontWeight, fontFamily, context.assets)
    val paintParams = PaintParams(typeface, fontSize)
    val size = measure(width, text, PaintParams(typeface, fontSize))

    if (id != null) {
      data[id] = MeasurementParams(true, width, size, text, paintParams)
    }

    return size
  }

  private fun getMeasureById(
    context: Context,
    id: Int?,
    width: Float,
    props: ReadableMap?,
  ): Long {
    val id = id ?: return initialMeasure(context, id, width, props)
    val value = data[id] ?: return initialMeasure(context, id, width, props)

    // First measure has to be done using initialMeasure
    // That way it's free of any side effects and async initializations
    if (!value.initialized) return initialMeasure(context, id, width, props)

    if (width == value.cachedWidth) {
      return value.cachedSize
    }

    val paint =
      TextPaint().apply {
        typeface = value.paintParams.typeface
        textSize = value.paintParams.fontSize
      }

    val size = measure(width, value.spannable, paint)
    data[id] = MeasurementParams(true, width, size, value.spannable, value.paintParams)
    return size
  }

  fun getMeasureById(
    context: Context,
    id: Int?,
    width: Float,
    height: Float,
    heightMode: YogaMeasureMode?,
    props: ReadableMap?,
  ): Long {
    val size = getMeasureById(context, id, width, props)
    if (heightMode !== YogaMeasureMode.AT_MOST) {
      return size
    }

    val calculatedHeight = YogaMeasureOutput.getHeight(size)
    val atMostHeight = PixelUtil.toDIPFromPixel(height)
    val finalHeight = calculatedHeight.coerceAtMost(atMostHeight)
    return YogaMeasureOutput.make(YogaMeasureOutput.getWidth(size), finalHeight)
  }
}
