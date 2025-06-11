package com.swmansion.reactnativerichtexteditor.watchers

import android.text.Editable
import android.text.TextWatcher
import com.facebook.react.bridge.ReactContext
import com.facebook.react.uimanager.UIManagerHelper
import com.swmansion.reactnativerichtexteditor.ReactNativeRichTextEditorView
import com.swmansion.reactnativerichtexteditor.events.OnChangeTextEvent

class EditorTextWatcher(private val editorView: ReactNativeRichTextEditorView) : TextWatcher {
  private var endCursorPosition: Int = 0
  private var previousTextLength: Int = 0

  override fun beforeTextChanged(s: CharSequence?, start: Int, count: Int, after: Int) {
    previousTextLength = s?.length ?: 0
  }

  override fun onTextChanged(s: CharSequence?, start: Int, before: Int, count: Int) {
    endCursorPosition = start + count
    editorView.layoutManager.measureSize(s ?: "")
  }

  override fun afterTextChanged(s: Editable?) {
    if (s == null) return
    emitEvents(s)

    if (editorView.isSettingValue) return
    applyStyles(s)
  }

  private fun applyStyles(s: Editable) {
    editorView.inlineStyles?.afterTextChanged(s, endCursorPosition)
    editorView.paragraphStyles?.afterTextChanged(s, endCursorPosition, previousTextLength)
    editorView.listStyles?.afterTextChanged(s, endCursorPosition, previousTextLength)
    editorView.parametrizedStyles?.afterTextChanged(s, endCursorPosition)
  }

  private fun emitEvents(s: Editable) {
    val context = editorView.context as ReactContext
    val surfaceId = UIManagerHelper.getSurfaceId(context)
    val dispatcher = UIManagerHelper.getEventDispatcherForReactTag(context, editorView.id)
    dispatcher?.dispatchEvent(OnChangeTextEvent(surfaceId, editorView.id, s))
    editorView.spanWatcher?.emitEvent(s, null)
  }
}
