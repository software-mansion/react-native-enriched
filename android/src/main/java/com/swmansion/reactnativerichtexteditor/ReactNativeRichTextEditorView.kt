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
  var mWidth: Int = 0

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
        measureTextHeight()
      }

      override fun afterTextChanged(s: Editable?) {
        val context = context as ReactContext
        val surfaceId = UIManagerHelper.getSurfaceId(context)
        val dispatcher = UIManagerHelper.getEventDispatcherForReactTag(context, id)
        dispatcher?.dispatchEvent(OnChangeTextEvent(surfaceId, id, s.toString()))
      }
    }

    // TODO: finalize proper styling
    this.width = this.mWidth
    this.isSingleLine = false
    this.setPadding(0, 0, 0, 0)
    this.setBackgroundColor(Color.LTGRAY)
    this.gravity = android.view.Gravity.CENTER or android.view.Gravity.START
    this.isHorizontalScrollBarEnabled = false
    addTextChangedListener(EditorTextWatcher())
  }

  override fun onAttachedToWindow() {
    super.onAttachedToWindow()

    measureTextHeight()
  }

  fun setStateWrapper(stateWrapper: StateWrapper?) {
    this.stateWrapper = stateWrapper
  }

  fun setDefaultValue(value: String?) {
    if (value != null) {
      setText(value)
    }
  }


  fun measureTextHeight() {
    val paint = this.paint
    val spannable = this.text as Spannable
    val spannableLength = spannable.length

    val staticLayout = StaticLayout.Builder
      .obtain(spannable, 0, spannableLength, paint, this.mWidth)
      .setIncludePad(false)
      .setLineSpacing(0f, 1f)
      .build()

    val heightInSP = PixelUtil.toDIPFromPixel(staticLayout.height.toFloat())
    val widthInSP = PixelUtil.toDIPFromPixel(this.mWidth.toFloat())

    stateWrapper?.updateState(Arguments.createMap().apply {
      putDouble("height", heightInSP.toDouble())
      putDouble("width", widthInSP.toDouble())
    })
  }
}
