package com.swmansion.enriched.utils

import android.text.Editable
import android.text.Spannable
import com.facebook.react.bridge.ReactContext
import com.facebook.react.uimanager.UIManagerHelper
import com.swmansion.enriched.EnrichedTextInputView
import com.swmansion.enriched.events.OnChangeSelectionEvent
import com.swmansion.enriched.events.OnLinkDetectedEvent
import com.swmansion.enriched.events.OnMentionDetectedEvent
import com.swmansion.enriched.spans.EnrichedLinkSpan
import com.swmansion.enriched.spans.EnrichedMentionSpan
import com.swmansion.enriched.spans.EnrichedSpans
import org.json.JSONObject

class EnrichedSelection(
  private val view: EnrichedTextInputView,
) {
  var start: Int = 0
  var end: Int = 0

  private var previousLinkDetectedEvent: MutableMap<String, String> = mutableMapOf("text" to "", "url" to "")
  private var previousMentionDetectedEvent: MutableMap<String, String> = mutableMapOf("text" to "", "payload" to "")

  fun onSelection(
    selStart: Int,
    selEnd: Int,
  ) {
    var shouldValidateStyles = false
    var newStart = start
    var newEnd = end

    if (selStart != -1 && selStart != newStart) {
      newStart = selStart
      shouldValidateStyles = true
    }

    if (selEnd != -1 && selEnd != newEnd) {
      newEnd = selEnd
      shouldValidateStyles = true
    }

    val textLength = view.text?.length ?: 0
    val finalStart = newStart.coerceAtMost(newEnd).coerceAtLeast(0).coerceAtMost(textLength)
    val finalEnd = newEnd.coerceAtLeast(newStart).coerceAtLeast(0).coerceAtMost(textLength)

    if (isZeroWidthSelection(finalStart, finalEnd) && !view.isDuringTransaction) {
      view.setSelection(finalStart + 1)
      shouldValidateStyles = false
    }

    if (!shouldValidateStyles) return

    start = finalStart
    end = finalEnd
    validateStyles()
    emitSelectionChangeEvent(view.text, finalStart, finalEnd)
  }

  private fun isZeroWidthSelection(
    start: Int,
    end: Int,
  ): Boolean {
    val text = view.text ?: return false

    if (start != end) {
      return text.substring(start, end) == EnrichedConstants.ZWS_STRING
    }

    val isNewLine = if (start > 0) text.substring(start - 1, start) == "\n" else true
    val isNextCharacterZeroWidth =
      if (start < text.length) {
        text.substring(start, start + 1) == EnrichedConstants.ZWS_STRING
      } else {
        false
      }

    return isNewLine && isNextCharacterZeroWidth
  }

  fun validateStyles() {
    val state = view.spanState ?: return

    // We don't validate inline styles when removing many characters at once
    // We don't want to remove styles on auto-correction
    // If user removes many characters at once, we want to keep the styles config
    if (!view.isRemovingMany) {
      for ((style, config) in EnrichedSpans.inlineSpans) {
        state.setStart(style, getInlineStyleStart(config.clazz))
      }
    } else {
      view.isRemovingMany = false
    }

    for ((style, config) in EnrichedSpans.paragraphSpans) {
      state.setStart(style, getParagraphStyleStart(config.clazz))
    }

    for ((style, config) in EnrichedSpans.listSpans) {
      state.setStart(style, getListStyleStart(config.clazz))
    }

    for ((style, config) in EnrichedSpans.parametrizedStyles) {
      state.setStart(style, getParametrizedStyleStart(config.clazz))
    }
  }

  fun getInlineSelection(): Pair<Int, Int> {
    val finalStart = start.coerceAtMost(end).coerceAtLeast(0)
    val finalEnd = end.coerceAtLeast(start).coerceAtLeast(0)

    return Pair(finalStart, finalEnd)
  }

  private fun <T> getInlineStyleStart(type: Class<T>): Int? {
    val (start, end) = getInlineSelection()
    val spannable = view.text as Spannable
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
    val spannable = view.text as Spannable
    return spannable.getParagraphBounds(currentStart, currentEnd)
  }

  private fun <T> getParagraphStyleStart(type: Class<T>): Int? {
    val (start, end) = getParagraphSelection()
    val spannable = view.text as Spannable
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

  private fun <T> getListStyleStart(type: Class<T>): Int? {
    val (start, end) = getParagraphSelection()
    val spannable = view.text as Spannable
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

  private fun <T> getParametrizedStyleStart(type: Class<T>): Int? {
    val (start, end) = getInlineSelection()
    val spannable = view.text as Spannable
    val spans = spannable.getSpans(start, end, type)
    val isLinkType = type == EnrichedLinkSpan::class.java
    val isMentionType = type == EnrichedMentionSpan::class.java

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
        if (isLinkType && span is EnrichedLinkSpan) {
          emitLinkDetectedEvent(spannable, span, spanStart, spanEnd)
        } else if (isMentionType && span is EnrichedMentionSpan) {
          emitMentionDetectedEvent(spannable, span, spanStart, spanEnd)
        }

        return spanStart
      }
    }

    return null
  }

  private fun emitSelectionChangeEvent(
    editable: Editable?,
    start: Int,
    end: Int,
  ) {
    if (editable == null) return

    val context = view.context as ReactContext
    val surfaceId = UIManagerHelper.getSurfaceId(context)
    val dispatcher = UIManagerHelper.getEventDispatcherForReactTag(context, view.id)

    val text = editable.substring(start, end)
    dispatcher?.dispatchEvent(
      OnChangeSelectionEvent(
        surfaceId,
        view.id,
        text,
        start,
        end,
        view.experimentalSynchronousEvents,
      ),
    )
  }

  private fun emitLinkDetectedEvent(
    spannable: Spannable,
    span: EnrichedLinkSpan?,
    start: Int,
    end: Int,
  ) {
    val text = spannable.substring(start, end)
    val url = span?.getUrl() ?: ""

    // Prevents emitting unnecessary events
    if (text == previousLinkDetectedEvent["text"] && url == previousLinkDetectedEvent["url"]) return

    previousLinkDetectedEvent.put("text", text)
    previousLinkDetectedEvent.put("url", url)

    val context = view.context as ReactContext
    val surfaceId = UIManagerHelper.getSurfaceId(context)
    val dispatcher = UIManagerHelper.getEventDispatcherForReactTag(context, view.id)
    dispatcher?.dispatchEvent(
      OnLinkDetectedEvent(
        surfaceId,
        view.id,
        text,
        url,
        start,
        end,
        view.experimentalSynchronousEvents,
      ),
    )
  }

  private fun emitMentionDetectedEvent(
    spannable: Spannable,
    span: EnrichedMentionSpan?,
    start: Int,
    end: Int,
  ) {
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

    val context = view.context as ReactContext
    val surfaceId = UIManagerHelper.getSurfaceId(context)
    val dispatcher = UIManagerHelper.getEventDispatcherForReactTag(context, view.id)
    dispatcher?.dispatchEvent(
      OnMentionDetectedEvent(
        surfaceId,
        view.id,
        text,
        indicator,
        payload,
        view.experimentalSynchronousEvents,
      ),
    )
  }
}
