package com.swmansion.reactnativerichtexteditor

import android.content.Context
import android.graphics.Color
import android.text.Editable
import android.text.Spannable
import android.text.StaticLayout
import android.text.TextWatcher
import android.util.AttributeSet
import androidx.appcompat.widget.AppCompatEditText
import com.facebook.react.bridge.Arguments
import com.facebook.react.bridge.ReactContext
import com.facebook.react.uimanager.PixelUtil
import com.facebook.react.uimanager.StateWrapper
import com.facebook.react.uimanager.UIManagerHelper


class ReactNativeRichTextEditorView : AppCompatEditText {
  private var stateWrapper: StateWrapper? = null

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
        updateYogaState(s.toString())
      }

      override fun afterTextChanged(s: Editable?) {
        val context = context as ReactContext
        val surfaceId = UIManagerHelper.getSurfaceId(context)
        val dispatcher = UIManagerHelper.getEventDispatcherForReactTag(context, id)
        dispatcher?.dispatchEvent(OnChangeTextEvent(surfaceId, id, s.toString()))
      }
    }

    // TODO: allow customizing font (color, size, family, weight, line height)

    // TODO: add borders support

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
    if (value != null) {
      setText(value)
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

  // Used for triggering layout recalculation
  private fun updateYogaState(text: String) {
    val state = Arguments.createMap()
    state.putString("text", text)
    stateWrapper?.updateState(state)
  }
}
