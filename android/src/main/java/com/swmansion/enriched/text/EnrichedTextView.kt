package com.swmansion.enriched.text

import android.content.ClipData
import android.content.ClipboardManager
import android.content.Context
import android.graphics.Color
import android.graphics.text.LineBreaker
import android.os.Build
import android.text.Spannable
import android.text.SpannableString
import android.text.Spanned
import android.text.TextUtils
import android.util.AttributeSet
import android.util.Log
import android.util.TypedValue
import android.view.MotionEvent
import androidx.appcompat.widget.AppCompatTextView
import com.facebook.react.bridge.ReactContext
import com.facebook.react.bridge.ReadableMap
import com.facebook.react.common.ReactConstants
import com.facebook.react.uimanager.ViewDefaults
import com.facebook.react.views.text.ReactTypefaceUtils.applyStyles
import com.facebook.react.views.text.ReactTypefaceUtils.parseFontStyle
import com.facebook.react.views.text.ReactTypefaceUtils.parseFontWeight
import com.swmansion.enriched.common.EnrichedConstants
import com.swmansion.enriched.common.EnrichedSpanFlags
import com.swmansion.enriched.common.GumboNormalizer
import com.swmansion.enriched.common.parser.EnrichedParser
import com.swmansion.enriched.common.pixelFromSpOrDp
import com.swmansion.enriched.text.spans.EnrichedTextImageSpan
import com.swmansion.enriched.text.spans.interfaces.EnrichedTextClickableSpan
import com.swmansion.enriched.text.spans.interfaces.EnrichedTextSpan
import kotlin.math.ceil

class EnrichedTextView : AppCompatTextView {
  private var valueDirty = false
  private var value: String? = null
  private var typefaceDirty = false
  private var fontFamily: String? = null
  private var fontStyle: Int = ReactConstants.UNSET
  private var fontWeight: Int = ReactConstants.UNSET
  private var fontSize: Float = EnrichedConstants.TEXT_DEFAULT_FONT_SIZE
  private var fontSizeRaw: Float? = null
  private var htmlStyleMap: ReadableMap? = null
  var allowFontScaling: Boolean = EnrichedConstants.ALLOW_FONT_SCALING_DEFAULT
    set(value) {
      if (field == value) return
      field = value
      fontSizeRaw?.let { setFontSize(it) }
      htmlStyleMap?.let { setHtmlStyle(it) }
    }

  private var enrichedStyle: EnrichedTextStyle? = null
  private val spannableFactory = EnrichedTextSpanFactory()

  // We keep the parsedText around so that when an async image finishes loading we can re-call
  // setText with the same instance and force the TextView to rebuild its layout.
  private var parsedText: CharSequence? = null

  var useHtmlNormalizer = false

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
    setFontSize(EnrichedConstants.TEXT_DEFAULT_FONT_SIZE)
  }

  override fun onTouchEvent(event: MotionEvent): Boolean {
    val spanned = text as? Spanned
    val action = event.action

    if (spanned == null || layout == null) {
      return super.onTouchEvent(event)
    }

    if (action == MotionEvent.ACTION_UP || action == MotionEvent.ACTION_DOWN || action == MotionEvent.ACTION_CANCEL) {
      val x = (event.x - totalPaddingLeft + scrollX).toInt()
      val y = (event.y - totalPaddingTop + scrollY).toInt()

      val line = layout.getLineForVertical(y)
      val off = layout.getOffsetForHorizontal(line, x.toFloat())

      val inLineBounds = x >= layout.getLineLeft(line) && x <= layout.getLineRight(line)
      val links =
        if (inLineBounds) {
          spanned.getSpans(off, off, EnrichedTextClickableSpan::class.java)
        } else {
          emptyArray()
        }

      if (links.isNotEmpty()) {
        val link = links[0]

        when (action) {
          MotionEvent.ACTION_DOWN -> {
            link.isPressed = true
          }

          MotionEvent.ACTION_UP -> {
            link.onClick(this)
            link.isPressed = false
            performClick()
          }

          MotionEvent.ACTION_CANCEL -> {
            link.isPressed = false
          }
        }

        invalidate()
        return true
      } else {
        val allSpans = spanned.getSpans(0, spanned.length, EnrichedTextClickableSpan::class.java)
        allSpans.forEach { it.isPressed = false }
        invalidate()
      }
    }

    return super.onTouchEvent(event)
  }

  // Required for accessibility when overriding onTouchEvent.
  override fun performClick(): Boolean {
    super.performClick()
    return true
  }

  override fun onTextContextMenuItem(id: Int): Boolean {
    when (id) {
      android.R.id.copy -> {
        handleCustomCopy()
        return true
      }
    }
    return super.onTextContextMenuItem(id)
  }

  private fun handleCustomCopy() {
    val start = selectionStart
    val end = selectionEnd
    val spannable = text as Spannable

    if (start < end) {
      val selectedText = spannable.subSequence(start, end) as Spannable
      val selectedHtml = EnrichedParser.toHtml(selectedText)

      val clipboard = context.getSystemService(Context.CLIPBOARD_SERVICE) as ClipboardManager
      val clip = ClipData.newHtmlText(EnrichedConstants.CLIPBOARD_TAG, selectedText, selectedHtml)
      clipboard.setPrimaryClip(clip)
    }
  }

  private fun updateValue() {
    val text = value ?: return
    val style = enrichedStyle ?: return
    if (!valueDirty) return

    valueDirty = false

    val parsed = parseText(text, style)
    if (parsed != null) {
      parsedText = parsed
      setText(parsed, BufferType.NORMAL)
      observeAsyncImages()
    } else {
      parsedText = null
      this.text = text
    }
  }

  private fun parseText(
    text: String,
    style: EnrichedTextStyle,
  ): CharSequence? {
    val isInternalHtml = text.startsWith("<html>") && text.endsWith("</html>")

    if (isInternalHtml) {
      try {
        val parsed = EnrichedParser.fromHtml(text, style, spannableFactory)
        return parsed.trimEnd('\n')
      } catch (e: Exception) {
        Log.e(TAG, "Error parsing HTML: ${e.message}")
        return normalizeHtmlIfNeeded(text, style)
      }
    }

    return normalizeHtmlIfNeeded(text, style)
  }

  private fun normalizeHtmlIfNeeded(
    text: String,
    style: EnrichedTextStyle,
  ): CharSequence? {
    if (!useHtmlNormalizer) return null
    return parseNormalizedHtml(text, style)
  }

  private fun parseNormalizedHtml(
    text: String,
    style: EnrichedTextStyle,
  ): CharSequence? {
    val normalized = GumboNormalizer.normalizeHtml(text) ?: return null

    return try {
      val parsed: Spanned = EnrichedParser.fromHtml(normalized, style, spannableFactory)
      parsed.trimEnd('\n')
    } catch (e: Exception) {
      Log.e(TAG, "Error parsing normalized HTML: ${e.message}")
      null
    }
  }

  private fun observeAsyncImages() {
    val spanned = parsedText as? Spanned ?: return
    val spans = spanned.getSpans(0, spanned.length, EnrichedTextImageSpan::class.java)
    for (span in spans) {
      span.observeAsyncDrawableLoaded {
        // Rebuild the TextView layout with the newly loaded drawable bounds.
        parsedText?.let { setText(it, BufferType.NORMAL) }
      }
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

    htmlStyleMap = style
    val enrichedStyle =
      EnrichedTextStyle.fromReadableMap(context as ReactContext, fontSize.toInt(), style, allowFontScaling)
    this.enrichedStyle = enrichedStyle

    val currentText = text ?: return
    if (currentText.isEmpty()) return

    val spannable = SpannableString(currentText)
    val spans = spannable.getSpans(0, spannable.length, EnrichedTextSpan::class.java)
    var modified = false

    for (span in spans) {
      val start = spannable.getSpanStart(span)
      val end = spannable.getSpanEnd(span)
      val flags = spannable.getSpanFlags(span)

      if (start == -1 || end == -1) continue

      spannable.removeSpan(span)
      val newSpan = span.rebuildWithStyle(enrichedStyle)
      spannable.setSpan(newSpan, start, end, EnrichedSpanFlags.forSpan(newSpan, flags))
      modified = true
    }

    if (modified) {
      this.text = spannable
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

    fontSizeRaw = size
    val sizeInt = ceil(pixelFromSpOrDp(size, allowFontScaling))
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

    if (fontWeight != this.fontWeight) {
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

  companion object {
    private const val TAG = "EnrichedTextView"
  }
}
