package com.swmansion.reactnativerichtexteditor

import android.text.Editable
import android.content.Context
import android.text.TextWatcher
import android.util.AttributeSet
import com.facebook.react.bridge.ReactContext
import androidx.appcompat.widget.AppCompatEditText
import com.facebook.react.uimanager.UIManagerHelper

class ReactNativeRichTextEditorView : AppCompatEditText {
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

  fun prepareComponent() {
    class EditorTextWatcher : TextWatcher {
      override fun beforeTextChanged(s: CharSequence?, start: Int, count: Int, after: Int) {}

      override fun onTextChanged(s: CharSequence?, start: Int, before: Int, count: Int) {}

      override fun afterTextChanged(s: Editable?) {
        val context = context as ReactContext
        val surfaceId = UIManagerHelper.getSurfaceId(context)
        val dispatcher = UIManagerHelper.getEventDispatcherForReactTag(context, id)
        dispatcher?.dispatchEvent(OnChangeTextEvent(surfaceId, id, s.toString()))
      }
    }

    addTextChangedListener(EditorTextWatcher())
  }


  fun setDefaultValue(value: String?) {
    if (value != null) {
      setText(value)
    }
  }
}
