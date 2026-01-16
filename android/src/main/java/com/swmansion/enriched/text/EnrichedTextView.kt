package com.swmansion.enriched.text

import android.content.Context
import android.graphics.Color
import android.graphics.text.LineBreaker
import android.os.Build
import android.text.Spannable
import android.text.TextUtils
import android.util.AttributeSet
import android.util.TypedValue
import androidx.appcompat.widget.AppCompatTextView
import com.facebook.react.bridge.ReactContext
import com.facebook.react.bridge.ReadableMap
import com.facebook.react.common.ReactConstants
import com.facebook.react.uimanager.PixelUtil
import com.facebook.react.uimanager.ViewDefaults
import com.facebook.react.views.text.ReactTypefaceUtils.applyStyles
import com.facebook.react.views.text.ReactTypefaceUtils.parseFontStyle
import com.facebook.react.views.text.ReactTypefaceUtils.parseFontWeight
import com.swmansion.enriched.common.parser.EnrichedParser
import com.swmansion.enriched.text.spans.interfaces.EnrichedTextSpan
import kotlin.math.ceil

class EnrichedTextView : AppCompatTextView {
  private var valueDirty = false
  private var value: String? = null
  private var typefaceDirty = false
  private var fontFamily: String? = null
  private var fontStyle: Int = ReactConstants.UNSET
  private var fontWeight: Int = ReactConstants.UNSET
  private var fontSize: Float = textSize

  private var enrichedStyle: EnrichedTextStyle? = null
  private val spannableFactory = EnrichedTextSpanFactory()

  constructor(context: Context) : super(context) {
    prepareComponent()
  }

  constructor(context: Context, attrs: AttributeSet) : super(context, attrs) {
    prepareComponent()
  }

  constructor(context: Context, attrs: AttributeSet, defStyleAttr: Int) : super(
    context,
    attrs,
    defStyleAttr,
  ) {
    prepareComponent()
  }

  private fun prepareComponent() {
    if (Build.VERSION.SDK_INT >= Build.VERSION_CODES.Q) {
      breakStrategy = LineBreaker.BREAK_STRATEGY_HIGH_QUALITY
    }

    setPadding(0, 0, 0, 0)
  }

  private fun updateValue() {
    val text = value ?: return
    val style = enrichedStyle ?: return
    if (!valueDirty) return

    valueDirty = false
    val isHtml = text.startsWith("<html>") && text.endsWith("</html>")
    if (!isHtml) {
      setText(text)
      return
    }

    try {
      val parsed = EnrichedParser.fromHtml(text, style, null, spannableFactory)
      val withoutLastNewLine = parsed.trimEnd('\n')
      setText(withoutLastNewLine, BufferType.SPANNABLE)
    } catch (e: Exception) {
      setText(text)
    }
  }

  private fun updateTypeface() {
    if (!typefaceDirty) return
    typefaceDirty = false

    val newTypeface = applyStyles(typeface, fontStyle, fontWeight, fontFamily, context.assets)
    typeface = newTypeface
    paint.typeface = newTypeface
  }

  fun setValue(text: String?) {
    value = text
    valueDirty = true
  }

  fun setHtmlStyle(style: ReadableMap?) {
    if (style == null) return

    val enrichedStyle = EnrichedTextStyle.fromReadableMap(context as ReactContext, style)
    this.enrichedStyle = enrichedStyle

    val spannable = text as? Spannable ?: return
    if (spannable.isEmpty()) return

    val spans = spannable.getSpans(0, spannable.length, EnrichedTextSpan::class.java)
    for (span in spans) {
      val start = spannable.getSpanStart(span)
      val end = spannable.getSpanEnd(span)
      val flags = spannable.getSpanFlags(span)

      if (start == -1 || end == -1) continue

      spannable.removeSpan(span)
      val newSpan = span.rebuildWithStyle(enrichedStyle)
      spannable.setSpan(newSpan, start, end, flags)
    }
  }

  fun setColor(colorInt: Int?) {
    if (colorInt == null) {
      setTextColor(Color.BLACK)
      return
    }

    setTextColor(colorInt)
  }

  fun setFontSize(size: Float) {
    if (size == 0f) return

    val sizeInt = ceil(PixelUtil.toPixelFromSP(size))
    fontSize = sizeInt
    setTextSize(TypedValue.COMPLEX_UNIT_PX, sizeInt)
  }

  fun setFontFamily(family: String?) {
    if (family != fontFamily) {
      fontFamily = family
      typefaceDirty = true
    }
  }

  fun setFontWeight(weight: String?) {
    val fontWeight = parseFontWeight(weight)

    if (fontWeight != fontStyle) {
      this.fontWeight = fontWeight
      typefaceDirty = true
    }
  }

  fun setFontStyle(style: String?) {
    val fontStyle = parseFontStyle(style)

    if (fontStyle != this.fontStyle) {
      this.fontStyle = fontStyle
      typefaceDirty = true
    }
  }

  fun setSelectionColor(colorInt: Int?) {
    if (colorInt == null) return

    highlightColor = colorInt
  }

  fun setEllipsizeMode(mode: String?) {
    ellipsize =
      when (mode) {
        "tail" -> TextUtils.TruncateAt.END
        "head" -> TextUtils.TruncateAt.START
        "middle" -> TextUtils.TruncateAt.MIDDLE
        "clip" -> null
        else -> TextUtils.TruncateAt.END
      }
  }

  fun setNumberOfLines(lines: Int) {
    maxLines = if (lines == 0) ViewDefaults.NUMBER_OF_LINES else lines
  }

  fun afterUpdateTransaction() {
    updateTypeface()
    updateValue()
  }
}
