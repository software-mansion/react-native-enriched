package com.swmansion.reactnativerichtexteditor.utils

import android.text.Editable
import android.text.Spannable
import android.util.Log
import com.facebook.react.bridge.ReactContext
import com.facebook.react.uimanager.UIManagerHelper
import com.swmansion.reactnativerichtexteditor.ReactNativeRichTextEditorView
import com.swmansion.reactnativerichtexteditor.events.OnChangeSelectionEvent
import com.swmansion.reactnativerichtexteditor.events.OnLinkDetectedEvent
import com.swmansion.reactnativerichtexteditor.events.OnMentionDetectedEvent
import com.swmansion.reactnativerichtexteditor.spans.EditorLinkSpan
import com.swmansion.reactnativerichtexteditor.spans.EditorMentionSpan
import com.swmansion.reactnativerichtexteditor.spans.EditorSpans
import org.json.JSONObject

class EditorSelection(private val editorView: ReactNativeRichTextEditorView) {
  var start: Int = 0
  var end: Int = 0

  private var previousLinkDetectedEvent: MutableMap<String, String> = mutableMapOf("text" to "", "url" to "")
  private var previousMentionDetectedEvent: MutableMap<String, String> = mutableMapOf("text" to "", "payload" to "")

  fun onSelection(selStart: Int, selEnd: Int) {
    var shouldValidateStyles = false

    if (selStart != -1 && selStart != start) {
      start = selStart
      shouldValidateStyles = true
    }

    if (selEnd != -1 && selEnd != end) {
      end = selEnd
      shouldValidateStyles = true
    }

    if (isZeroWidthSelection() && !editorView.isSettingValue) {
      editorView.setSelection(start + 1)
      shouldValidateStyles = false
    }

    if (!shouldValidateStyles) return

    validateStyles()
    emitSelectionChangeEvent(editorView.text, start, end)
  }

  private fun isZeroWidthSelection(): Boolean {
    val text = editorView.text ?: return false
    val start = this.start.coerceAtLeast(0).coerceAtMost(text.length)
    val end = this.end.coerceAtLeast(0).coerceAtMost(text.length)

    Log.d("EditorSelection", "Checking zero-width selection: start=$start, end=$end, text=${text}, text.length=${text.length}")

    if (start != end) {
      return text.substring(start, end) == "\u200B"
    }

    val isNewLine = if (start > 0 ) text.substring(start - 1, start) == "\n" else true
    val isNextCharacterZeroWidth = if (start < text.length) {
      text.substring(start, start + 1) == "\u200B"
    } else {
      false
    }

    return isNewLine && isNextCharacterZeroWidth
  }

  fun validateStyles() {
    val state = editorView.spanState ?: return

    // We don't validate inline styles when removing many characters at once
    // We don't want to remove styles on auto-correction
    // If user removes many characters at once, we want to keep the styles config
    if (!editorView.isRemovingMany) {
      for ((style, config) in EditorSpans.inlineSpans) {
        state.setStart(style, getInlineStyleStart(config.clazz))
      }
    } else {
      editorView.isRemovingMany = false
    }

    for ((style, config) in EditorSpans.paragraphSpans) {
      state.setStart(style, getParagraphStyleStart(config.clazz))
    }

    for ((style, config) in EditorSpans.listSpans) {
      state.setStart(style, getListStyleStart(config.clazz))
    }

    for ((style, config) in EditorSpans.parametrizedStyles) {
      state.setStart(style, getParametrizedStyleStart(config.clazz))
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

  fun getParagraphSelection(): Pair<Int, Int> {
    val (currentStart, currentEnd) = getInlineSelection()
    val spannable = editorView.text as Spannable
    return spannable.getParagraphBounds(currentStart, currentEnd)
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

  private fun <T>getParametrizedStyleStart(type: Class<T>): Int? {
    val (start, end) = getInlineSelection()
    val spannable = editorView.text as Spannable
    val spans = spannable.getSpans(start, end, type)
    val isLinkType = type == EditorLinkSpan::class.java
    val isMentionType = type == EditorMentionSpan::class.java

    if (isLinkType && spans.isEmpty()) {
      emitLinkDetectedEvent(spannable, null, start, end)
      return null
    }

    if (isMentionType && spans.isEmpty()) {
      emitMentionDetectedEvent(spannable, null, start, end)
      return null
    }

    for (span in spans) {
      val spanStart = spannable.getSpanStart(span)
      val spanEnd = spannable.getSpanEnd(span)

      if (start >= spanStart && end <= spanEnd) {
        if (isLinkType && span is EditorLinkSpan) {
          emitLinkDetectedEvent(spannable, span, spanStart, spanEnd)
        } else if (isMentionType && span is EditorMentionSpan) {
          emitMentionDetectedEvent(spannable, span, spanStart, spanEnd)
        }

        return spanStart
      }
    }

    return null
  }

  private fun emitSelectionChangeEvent(editable: Editable?, start: Int, end: Int) {
    if (editable == null) return

    val context = editorView.context as ReactContext
    val surfaceId = UIManagerHelper.getSurfaceId(context)
    val dispatcher = UIManagerHelper.getEventDispatcherForReactTag(context, editorView.id)

    val text = editable.substring(start, end)
    dispatcher?.dispatchEvent(OnChangeSelectionEvent(surfaceId, editorView.id, text, start ,end))
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

  private fun emitMentionDetectedEvent(spannable: Spannable, span: EditorMentionSpan?, start: Int, end: Int) {
    val text = spannable.substring(start, end)
    val attributes = span?.getAttributes() ?: emptyMap()
    val indicator = span?.getIndicator() ?: ""
    val payload = JSONObject(attributes).toString()

    val previousText = previousMentionDetectedEvent["text"] ?: ""
    val previousPayload = previousMentionDetectedEvent["payload"] ?: ""
    val previousIndicator = previousMentionDetectedEvent["indicator"] ?: ""

    if (text == previousText && payload == previousPayload && indicator == previousIndicator) return

    previousMentionDetectedEvent.put("text", text)
    previousMentionDetectedEvent.put("payload", payload)
    previousMentionDetectedEvent.put("indicator", indicator)

    val context = editorView.context as ReactContext
    val surfaceId = UIManagerHelper.getSurfaceId(context)
    val dispatcher = UIManagerHelper.getEventDispatcherForReactTag(context, editorView.id)
    dispatcher?.dispatchEvent(OnMentionDetectedEvent(surfaceId, editorView.id, text, indicator, payload))
  }
}
