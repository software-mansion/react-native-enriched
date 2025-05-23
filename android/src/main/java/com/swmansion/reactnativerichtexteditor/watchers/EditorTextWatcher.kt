package com.swmansion.reactnativerichtexteditor.watchers

import android.text.Editable
import android.text.TextWatcher
import com.facebook.react.bridge.ReactContext
import com.facebook.react.uimanager.UIManagerHelper
import com.swmansion.reactnativerichtexteditor.ReactNativeRichTextEditorView
import com.swmansion.reactnativerichtexteditor.events.OnChangeHtmlEvent
import com.swmansion.reactnativerichtexteditor.events.OnChangeTextEvent

class EditorTextWatcher(private val editorView: ReactNativeRichTextEditorView) : TextWatcher {
  private var endCursorPosition: Int = 0
  private var previousTextLength: Int = 0

  override fun beforeTextChanged(s: CharSequence?, start: Int, count: Int, after: Int) {
    previousTextLength = s?.length ?: 0
  }

  override fun onTextChanged(s: CharSequence?, start: Int, before: Int, count: Int) {
    endCursorPosition = start + count
    editorView.updateYogaState()
  }

  override fun afterTextChanged(s: Editable?) {
    if (s == null || editorView.isSettingValue) return

    emitEvent(s)
    applyStyles(s)
  }

  private fun applyStyles(s: Editable) {
    editorView.inlineStyles?.afterTextChanged(s, endCursorPosition)
    editorView.paragraphStyles?.afterTextChanged(s, endCursorPosition, previousTextLength)
    editorView.listStyles?.afterTextChanged(s, endCursorPosition, previousTextLength)
    editorView.parametrizedStyles?.afterTextChanged(s, endCursorPosition)
  }

  private fun emitEvent(s: Editable) {
    val context = editorView.context as ReactContext
    val surfaceId = UIManagerHelper.getSurfaceId(context)
    val dispatcher = UIManagerHelper.getEventDispatcherForReactTag(context, editorView.id)
    dispatcher?.dispatchEvent(OnChangeTextEvent(surfaceId, editorView.id, s))

    // For empty text we have to manually emit HTML event from TextWatcher instead of SpanWatcher
    if (s.isEmpty()) {
      dispatcher?.dispatchEvent(OnChangeHtmlEvent(surfaceId, editorView.id, ""))
    }
  }
}
