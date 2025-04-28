package com.swmansion.reactnativerichtexteditor

import android.content.Context
import android.graphics.Color
import android.text.Editable
import android.text.Spannable
import android.text.StaticLayout
import android.text.TextWatcher
import android.util.AttributeSet
import android.util.TypedValue
import androidx.appcompat.widget.AppCompatEditText
import com.facebook.react.bridge.Arguments
import com.facebook.react.bridge.ReactContext
import com.facebook.react.common.ReactConstants
import com.facebook.react.uimanager.PixelUtil
import com.facebook.react.uimanager.StateWrapper
import com.facebook.react.uimanager.UIManagerHelper
import com.facebook.react.views.text.ReactTypefaceUtils.applyStyles
import com.facebook.react.views.text.ReactTypefaceUtils.parseFontStyle
import com.facebook.react.views.text.ReactTypefaceUtils.parseFontWeight
import kotlin.math.ceil


class ReactNativeRichTextEditorView : AppCompatEditText {
  private var stateWrapper: StateWrapper? = null

  private var typefaceDirty = false
  private var fontSize: Float? = null
  private var fontFamily: String? = null
  private var fontStyle: Int = ReactConstants.UNSET
  private var fontWeight: Int = ReactConstants.UNSET
  private var forceHeightRecalculationCounter: Int = 0

  constructor(context: Context) : super(context) {
    prepareComponent()
  }

  constructor(context: Context, attrs: AttributeSet) : super(context, attrs) {
    prepareComponent()
  }

  constructor(context: Context, attrs: AttributeSet, defStyleAttr: Int) : super(
    context,
    attrs,
    defStyleAttr
  ) {
    prepareComponent()
  }

  private fun prepareComponent() {
    class EditorTextWatcher : TextWatcher {
      override fun beforeTextChanged(s: CharSequence?, start: Int, count: Int, after: Int) {}

      override fun onTextChanged(s: CharSequence?, start: Int, before: Int, count: Int) {
        updateYogaState()
      }

      override fun afterTextChanged(s: Editable?) {
        val context = context as ReactContext
        val surfaceId = UIManagerHelper.getSurfaceId(context)
        val dispatcher = UIManagerHelper.getEventDispatcherForReactTag(context, id)
        dispatcher?.dispatchEvent(OnChangeTextEvent(surfaceId, id, s.toString()))
      }
    }

    this.isSingleLine = false
    this.setPadding(0, 0, 0, 0)
    this.setBackgroundColor(Color.TRANSPARENT)
    this.gravity = android.view.Gravity.CENTER or android.view.Gravity.START
    this.isHorizontalScrollBarEnabled = false
    addTextChangedListener(EditorTextWatcher())
  }

  override fun onAttachedToWindow() {
    super.onAttachedToWindow()
  }

  fun setStateWrapper(stateWrapper: StateWrapper?) {
    this.stateWrapper = stateWrapper
  }

  fun setDefaultValue(value: String?) {
    if (value == null) return

    setText(value)
  }

  fun setColor(colorInt: Int?) {
    if (colorInt == null) {
      this.setTextColor(Color.BLACK)
      return
    }

    this.setTextColor(colorInt)
  }

  fun setFontSize(size: Float) {
    if (size == 0f) return

    val sizeInt = ceil(PixelUtil.toPixelFromSP(size))
    fontSize = sizeInt
    setTextSize(TypedValue.COMPLEX_UNIT_PX, sizeInt)

    updateYogaState()
  }

  fun setFontFamily(family: String?) {
    if (family != this.fontFamily) {
      this.fontFamily = family
      typefaceDirty = true
    }
  }

  fun setFontWeight(weight: String?) {
    val fontWeight = parseFontWeight(weight)

    if (fontWeight != this.fontStyle) {
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

  fun measureSize(maxWidth: Float): Pair<Float, Float> {
    val paint = this.paint
    val spannable = this.text as Spannable
    val spannableLength = spannable.length

    val staticLayout = StaticLayout.Builder
      .obtain(spannable, 0, spannableLength, paint, maxWidth.toInt())
      .setIncludePad(true)
      .setLineSpacing(0f, 1f)
      .build()

    val heightInSP = PixelUtil.toDIPFromPixel(staticLayout.height.toFloat())
    val widthInSP = PixelUtil.toDIPFromPixel(maxWidth)

    return Pair(widthInSP, heightInSP)
  }

  fun updateTypeface() {
    if (!typefaceDirty) return
    typefaceDirty = false

    val newTypeface = applyStyles(typeface, fontStyle, fontWeight, fontFamily, context.assets)
    typeface = newTypeface
    paint.typeface = newTypeface

    updateYogaState()
  }

  // Used for triggering layout recalculation
  private fun updateYogaState() {
    val counter = forceHeightRecalculationCounter
    forceHeightRecalculationCounter++
    val state = Arguments.createMap()

    state.putInt("forceHeightRecalculationCounter", counter)
    stateWrapper?.updateState(state)
  }

  override fun onDetachedFromWindow() {
    forceHeightRecalculationCounter = 0

    super.onDetachedFromWindow()
  }
}
