package com.swmansion.reactnativerichtexteditor

import android.content.Context
import android.os.Build
import android.text.Editable
import android.text.Layout
import android.text.StaticLayout
import android.text.TextWatcher
import android.util.AttributeSet
import android.util.Log
import android.view.ViewGroup
import androidx.annotation.RequiresApi
import androidx.appcompat.widget.AppCompatEditText
import com.facebook.react.bridge.Arguments
import com.facebook.react.bridge.ReactContext
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

      override fun onTextChanged(s: CharSequence?, start: Int, before: Int, count: Int) {}

      override fun afterTextChanged(s: Editable?) {
        updateSize()

        val context = context as ReactContext
        val surfaceId = UIManagerHelper.getSurfaceId(context)
        val dispatcher = UIManagerHelper.getEventDispatcherForReactTag(context, id)
        dispatcher?.dispatchEvent(OnChangeTextEvent(surfaceId, id, s.toString()))
      }
    }


    this.inputType = android.text.InputType.TYPE_TEXT_FLAG_MULTI_LINE
    this.width = 300
    addTextChangedListener(EditorTextWatcher())
  }

  @RequiresApi(Build.VERSION_CODES.Q)
  override fun onAttachedToWindow() {
    super.onAttachedToWindow()

    updateSize()
  }

  private fun updateSize() {
    this.measure(0, 0)
    val height = this.measuredHeight / 2.0
    val width = this.measuredWidth

    Log.d("ReactNativeRichTextEditorView", "Height: $height, width: ${this.measuredWidth}, measured: ${this.measuredHeight}")

    stateWrapper?.updateState(Arguments.createMap().apply {
      putDouble("height", height)
      putDouble("width", width.toDouble())
    })
  }

  fun setStateWrapper(stateWrapper: StateWrapper?) {
    this.stateWrapper = stateWrapper
  }

  fun setDefaultValue(value: String?) {
    if (value != null) {
      setText(value)
    }
  }
}
