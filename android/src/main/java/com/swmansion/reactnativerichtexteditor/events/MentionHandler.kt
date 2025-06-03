package com.swmansion.reactnativerichtexteditor.events

import com.facebook.react.bridge.ReactContext
import com.facebook.react.uimanager.UIManagerHelper
import com.swmansion.reactnativerichtexteditor.ReactNativeRichTextEditorView

class MentionHandler(private val editorView: ReactNativeRichTextEditorView) {
  private var previousText: String? = null
  private var previousIndicator: String? = null

  fun endMention() {
    val indicator = previousIndicator
    if (indicator == null) return

    emitEvent(indicator, null)
    previousIndicator = null
  }

  fun onMention(indicator: String, text: String?) {
    emitEvent(indicator, text)
    previousIndicator = indicator
  }

  private fun emitEvent(indicator: String, text: String?) {
    // Do not emit events too often
    if (previousText == text) return

    previousText = text
    val context = editorView.context as ReactContext
    val surfaceId = UIManagerHelper.getSurfaceId(context)
    val dispatcher = UIManagerHelper.getEventDispatcherForReactTag(context, editorView.id)
    dispatcher?.dispatchEvent(OnMentionEvent(surfaceId, editorView.id, indicator, text))
  }
}
