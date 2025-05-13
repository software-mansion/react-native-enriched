package com.swmansion.reactnativerichtexteditor.utils

import android.text.Spannable
import com.facebook.react.bridge.ReactContext
import com.facebook.react.uimanager.UIManagerHelper
import com.swmansion.reactnativerichtexteditor.ReactNativeRichTextEditorView
import com.swmansion.reactnativerichtexteditor.events.OnLinkDetectedEvent
import com.swmansion.reactnativerichtexteditor.spans.EditorLinkSpan
import com.swmansion.reactnativerichtexteditor.spans.EditorSpans

class EditorSelection(private val editorView: ReactNativeRichTextEditorView) {
  var start: Int = 0
  var end: Int = 0

  private var previousLinkDetectedEvent: MutableMap<String, String> = mutableMapOf("text" to "", "url" to "")

  fun onSelection(selStart: Int, selEnd: Int) {
    start = selStart
    end = selEnd

    this.validateStyles()
  }

  fun validateStyles() {
    val state = editorView.spanState ?: return

    for ((style, config) in EditorSpans.inlineSpans) {
      state.setStart(style, getInlineStyleStart(config.clazz))
    }

    for ((style, config) in EditorSpans.paragraphSpans) {
      state.setStart(style, getParagraphStyleStart(config.clazz))
    }

    for ((style, config) in EditorSpans.listSpans) {
      state.setStart(style, getListStyleStart(config.clazz))
    }

    for ((style, config) in EditorSpans.specialStyles) {
      state.setStart(style, getSpecialStyleStart(config.clazz))
    }
  }

  fun getInlineSelection(): Pair<Int, Int> {
    val finalStart = start.coerceAtMost(end).coerceAtLeast(0)
    val finalEnd = end.coerceAtLeast(start).coerceAtLeast(0)

    return Pair(finalStart, finalEnd)
  }

  private fun <T>getInlineStyleStart(type: Class<T>): Int? {
    val (start, end) = getInlineSelection()
    val spannable = editorView.text as Spannable
    val spans = spannable.getSpans(start, end, type)
    var styleStart: Int? = null

    for (span in spans) {
      val spanStart = spannable.getSpanStart(span)
      val spanEnd = spannable.getSpanEnd(span)

      if (start == end && start == spanStart) {
        styleStart = null
      } else if (start >= spanStart && end <= spanEnd) {
        styleStart = spanStart
      }
    }

    return styleStart
  }

  fun getParagraphBounds(spannable: Spannable, index: Int): Pair<Int, Int> {
    return getParagraphBounds(spannable, index, index)
  }

  fun getParagraphBounds(spannable: Spannable, start: Int, end: Int): Pair<Int, Int> {
    var startPosition = start.coerceAtLeast(0).coerceAtMost(spannable.length)
    var endPosition = end.coerceAtLeast(0).coerceAtMost(spannable.length)

    // Find the start of the paragraph
    while (startPosition > 0 && spannable[startPosition - 1] != '\n') {
      startPosition--
    }

    // Find the end of the paragraph
    while (endPosition < spannable.length && spannable[endPosition] != '\n') {
      endPosition++
    }

    return Pair(startPosition, endPosition)
  }

  fun getParagraphSelection(): Pair<Int, Int> {
    val (currentStart, currentEnd) = getInlineSelection()
    val spannable = editorView.text as Spannable
    return getParagraphBounds(spannable, currentStart, currentEnd)
  }

  private fun <T>getParagraphStyleStart(type: Class<T>): Int? {
    val (start, end) = getParagraphSelection()
    val spannable = editorView.text as Spannable
    val spans = spannable.getSpans(start, end, type)
    var styleStart: Int? = null

    for (span in spans) {
      val spanStart = spannable.getSpanStart(span)
      val spanEnd = spannable.getSpanEnd(span)

      if (start >= spanStart && end <= spanEnd) {
        styleStart = spanStart
        break
      }
    }

    return styleStart
  }

  private fun <T>getListStyleStart(type: Class<T>): Int? {
    val (start, end) = getParagraphSelection()
    val spannable = editorView.text as Spannable
    var styleStart: Int? = null

    var paragraphStart = start
    val paragraphs = spannable.substring(start, end).split("\n")
    pi@ for (paragraph in paragraphs) {
      val paragraphEnd = paragraphStart + paragraph.length
      val spans = spannable.getSpans(paragraphStart, paragraphEnd, type)

      for (span in spans) {
        val spanStart = spannable.getSpanStart(span)
        val spanEnd = spannable.getSpanEnd(span)

        if (spanStart == paragraphStart && spanEnd == paragraphEnd) {
          styleStart = spanStart
          paragraphStart = paragraphEnd + 1
          continue@pi
        }
      }

      styleStart = null
      break
    }

    return styleStart
  }

  private fun <T>getSpecialStyleStart(type: Class<T>): Int? {
    val (start, end) = getInlineSelection()
    val spannable = editorView.text as Spannable
    val spans = spannable.getSpans(start, end, type)

    if (spans.isEmpty()) {
      emitLinkDetectedEvent(spannable, null, start, end)
      return null
    }

    for (span in spans) {
      val spanStart = spannable.getSpanStart(span)
      val spanEnd = spannable.getSpanEnd(span)

      if (start >= spanStart && end <= spanEnd) {
        if (span is EditorLinkSpan) {
          emitLinkDetectedEvent(spannable, span, spanStart, spanEnd)
        }

        return spanStart
      }
    }

    return null
  }

  private fun emitLinkDetectedEvent(spannable: Spannable, span: EditorLinkSpan?, start: Int, end: Int) {
    val text = spannable.substring(start, end)
    val url = span?.getUrl() ?: ""

    // Prevents emitting unnecessary events
    if (text == previousLinkDetectedEvent["text"] && url == previousLinkDetectedEvent["url"]) return

    previousLinkDetectedEvent.put("text", text)
    previousLinkDetectedEvent.put("url", url)

    val context = editorView.context as ReactContext
    val surfaceId = UIManagerHelper.getSurfaceId(context)
    val dispatcher = UIManagerHelper.getEventDispatcherForReactTag(context, editorView.id)
    dispatcher?.dispatchEvent(OnLinkDetectedEvent(surfaceId, editorView.id, text, url))
  }
}
