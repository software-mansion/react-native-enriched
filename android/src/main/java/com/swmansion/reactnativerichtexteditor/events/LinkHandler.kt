package com.swmansion.reactnativerichtexteditor.events

import com.facebook.react.bridge.ReactContext
import com.facebook.react.uimanager.UIManagerHelper
import com.swmansion.reactnativerichtexteditor.ReactNativeRichTextEditorView

class LinkHandler(private val editorView: ReactNativeRichTextEditorView) {
  fun onClick(url: String) {
    val context = editorView.context as ReactContext
    val surfaceId = UIManagerHelper.getSurfaceId(context)
    val dispatcher = UIManagerHelper.getEventDispatcherForReactTag(context, editorView.id)
    dispatcher?.dispatchEvent(OnPressLinkEvent(surfaceId, editorView.id, url))
  }
}
