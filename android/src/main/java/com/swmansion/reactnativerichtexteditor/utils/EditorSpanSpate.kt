package com.swmansion.reactnativerichtexteditor.utils

import com.facebook.react.bridge.Arguments
import com.facebook.react.bridge.ReactContext
import com.facebook.react.bridge.WritableMap
import com.facebook.react.uimanager.UIManagerHelper
import com.swmansion.reactnativerichtexteditor.ReactNativeRichTextEditorView
import com.swmansion.reactnativerichtexteditor.events.OnChangeStyleEvent
import com.swmansion.reactnativerichtexteditor.spans.EditorSpans

class EditorSpanState(private val editorView: ReactNativeRichTextEditorView) {
  private var previousPayload: WritableMap? = null

  var boldStart: Int? = null
    private set
  var italicStart: Int? = null
    private set
  var underlineStart: Int? = null
    private set
  var strikethroughStart: Int? = null
    private set

  fun setBoldStart(start: Int?) {
    this.boldStart = start
    emitStyleChangeEvent()
  }

  fun setItalicStart(start: Int?) {
    this.italicStart = start
    emitStyleChangeEvent()
  }

  fun setUnderlineStart(start: Int?) {
    this.underlineStart = start
    emitStyleChangeEvent()
  }

  fun setStrikethroughStart(start: Int?) {
    this.strikethroughStart = start
    emitStyleChangeEvent()
  }

  fun getStart(name: String): Int? {
    val start = when (name) {
      EditorSpans.BOLD -> boldStart
      EditorSpans.ITALIC -> italicStart
      EditorSpans.UNDERLINE -> underlineStart
      EditorSpans.STRIKETHROUGH -> strikethroughStart
      else -> null
    }

    return start
  }

  fun setStart(name: String, start: Int?) {
    when (name) {
      EditorSpans.BOLD -> setBoldStart(start)
      EditorSpans.ITALIC -> setItalicStart(start)
      EditorSpans.UNDERLINE -> setUnderlineStart(start)
      EditorSpans.STRIKETHROUGH -> setStrikethroughStart(start)
    }
  }

  private fun emitStyleChangeEvent() {
    val payload: WritableMap = Arguments.createMap()
    payload.putBoolean("isBold", boldStart != null)
    payload.putBoolean("isItalic", italicStart != null)
    payload.putBoolean("isUnderline", underlineStart != null)
    payload.putBoolean("isStrikeThrough", strikethroughStart != null)

    // Do not emit event if payload is the same
    if (previousPayload == payload) {
      return
    }

    previousPayload = payload
    val context = editorView.context as ReactContext
    val surfaceId = UIManagerHelper.getSurfaceId(context)
    val dispatcher = UIManagerHelper.getEventDispatcherForReactTag(context, editorView.id)
    dispatcher?.dispatchEvent(OnChangeStyleEvent(surfaceId, editorView.id, payload))
  }

  companion object {
    const val NAME = "ReactNativeRichTextEditorView"
  }
}
