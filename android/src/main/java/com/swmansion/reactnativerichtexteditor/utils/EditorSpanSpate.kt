package com.swmansion.reactnativerichtexteditor.utils

import com.swmansion.reactnativerichtexteditor.ReactNativeRichTextEditorView
import com.swmansion.reactnativerichtexteditor.spans.EditorSpans

class EditorSpanSpate(private val editorView: ReactNativeRichTextEditorView) {
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
//    notifyAboutStateChange()
  }

  fun setItalicStart(start: Int?) {
    this.italicStart = start
//    notifyAboutStateChange()
  }

  fun setUnderlineStart(start: Int?) {
    this.underlineStart = start
//    notifyAboutStateChange()
  }

  fun setStrikethroughStart(start: Int?) {
    this.strikethroughStart = start
//    notifyAboutStateChange()
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
}
