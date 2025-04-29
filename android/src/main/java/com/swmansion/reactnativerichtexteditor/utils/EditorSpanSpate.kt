package com.swmansion.reactnativerichtexteditor.utils

import com.facebook.react.bridge.Arguments
import com.facebook.react.bridge.ReactContext
import com.facebook.react.bridge.WritableMap
import com.facebook.react.uimanager.UIManagerHelper
import com.swmansion.reactnativerichtexteditor.ReactNativeRichTextEditorView
import com.swmansion.reactnativerichtexteditor.events.OnChangeStyleEvent
import com.swmansion.reactnativerichtexteditor.spans.EditorSpans

class EditorSpanState(private val editorView: ReactNativeRichTextEditorView) {
  var boldStart: Int? = null
    private set
  var italicStart: Int? = null
    private set
  var underlineStart: Int? = null
    private set
  var strikethroughStart: Int? = null
    private set
  var h1Start: Int? = null
    private set
  var h2Start: Int? = null
    private set
  var h3Start: Int? = null
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

  fun setH1Start(start: Int?) {
    this.h1Start = start
    emitStyleChangeEvent()
  }

  fun setH2Start(start: Int?) {
    this.h2Start = start
    emitStyleChangeEvent()
  }

  fun setH3Start(start: Int?) {
    this.h3Start = start
    emitStyleChangeEvent()
  }

  fun getStart(name: String): Int? {
    val start = when (name) {
      EditorSpans.BOLD -> boldStart
      EditorSpans.ITALIC -> italicStart
      EditorSpans.UNDERLINE -> underlineStart
      EditorSpans.STRIKETHROUGH -> strikethroughStart
      EditorSpans.H1 -> h1Start
      EditorSpans.H2 -> h2Start
      EditorSpans.H3 -> h3Start
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
      EditorSpans.H1 -> setH1Start(start)
      EditorSpans.H2 -> setH2Start(start)
      EditorSpans.H3 -> setH3Start(start)
    }
  }

  // TODO: avoid emitting event if payload does not change
  private fun emitStyleChangeEvent() {
    val payload: WritableMap = Arguments.createMap()
    payload.putBoolean("isBold", boldStart != null)
    payload.putBoolean("isItalic", italicStart != null)
    payload.putBoolean("isUnderline", underlineStart != null)
    payload.putBoolean("isStrikeThrough", strikethroughStart != null)
    payload.putBoolean("isH1", h1Start != null)
    payload.putBoolean("isH2", h2Start != null)
    payload.putBoolean("isH3", h3Start != null)

    val context = editorView.context as ReactContext
    val surfaceId = UIManagerHelper.getSurfaceId(context)
    val dispatcher = UIManagerHelper.getEventDispatcherForReactTag(context, editorView.id)
    dispatcher?.dispatchEvent(OnChangeStyleEvent(surfaceId, editorView.id, payload))
  }

  companion object {
    const val NAME = "ReactNativeRichTextEditorView"
  }
}
