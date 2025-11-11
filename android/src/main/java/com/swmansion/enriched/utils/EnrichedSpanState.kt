package com.swmansion.enriched.utils

import com.facebook.react.bridge.Arguments
import com.facebook.react.bridge.ReactContext
import com.facebook.react.bridge.WritableMap
import com.facebook.react.uimanager.UIManagerHelper
import com.swmansion.enriched.EnrichedTextInputView
import com.swmansion.enriched.events.OnChangeStateEvent
import com.swmansion.enriched.spans.EnrichedSpans

class EnrichedSpanState(
  private val view: EnrichedTextInputView,
) {
  private var previousPayload: WritableMap? = null

  var boldStart: Int? = null
    private set
  var italicStart: Int? = null
    private set
  var underlineStart: Int? = null
    private set
  var strikethroughStart: Int? = null
    private set
  var inlineCodeStart: Int? = null
    private set
  var h1Start: Int? = null
    private set
  var h2Start: Int? = null
    private set
  var h3Start: Int? = null
    private set
  var h4Start: Int? = null
    private set
  var h5Start: Int? = null
    private set
  var h6Start: Int? = null
    private set
  var codeBlockStart: Int? = null
    private set
  var blockQuoteStart: Int? = null
    private set
  var orderedListStart: Int? = null
    private set
  var unorderedListStart: Int? = null
    private set
  var linkStart: Int? = null
    private set
  var imageStart: Int? = null
    private set
  var mentionStart: Int? = null
    private set

  fun setBoldStart(start: Int?) {
    this.boldStart = start
    emitStateChangeEvent()
  }

  fun setItalicStart(start: Int?) {
    this.italicStart = start
    emitStateChangeEvent()
  }

  fun setUnderlineStart(start: Int?) {
    this.underlineStart = start
    emitStateChangeEvent()
  }

  fun setStrikethroughStart(start: Int?) {
    this.strikethroughStart = start
    emitStateChangeEvent()
  }

  fun setInlineCodeStart(start: Int?) {
    this.inlineCodeStart = start
    emitStateChangeEvent()
  }

  fun setH1Start(start: Int?) {
    this.h1Start = start
    emitStateChangeEvent()
  }

  fun setH2Start(start: Int?) {
    this.h2Start = start
    emitStateChangeEvent()
  }

  fun setH3Start(start: Int?) {
    this.h3Start = start
    emitStateChangeEvent()
  }

  fun setH4Start(start: Int?) {
    this.h4Start = start
    emitStateChangeEvent()
  }

  fun setH5Start(start: Int?) {
    this.h5Start = start
    emitStateChangeEvent()
  }

  fun setH6Start(start: Int?) {
    this.h6Start = start
    emitStateChangeEvent()
  }

  fun setCodeBlockStart(start: Int?) {
    this.codeBlockStart = start
    emitStateChangeEvent()
  }

  fun setBlockQuoteStart(start: Int?) {
    this.blockQuoteStart = start
    emitStateChangeEvent()
  }

  fun setOrderedListStart(start: Int?) {
    this.orderedListStart = start
    emitStateChangeEvent()
  }

  fun setUnorderedListStart(start: Int?) {
    this.unorderedListStart = start
    emitStateChangeEvent()
  }

  fun setLinkStart(start: Int?) {
    this.linkStart = start
    emitStateChangeEvent()
  }

  fun setImageStart(start: Int?) {
    this.imageStart = start
    emitStateChangeEvent()
  }

  fun setMentionStart(start: Int?) {
    this.mentionStart = start
    emitStateChangeEvent()
  }

  fun getStart(name: String): Int? {
    val start = when (name) {
      EnrichedSpans.BOLD -> boldStart
      EnrichedSpans.ITALIC -> italicStart
      EnrichedSpans.UNDERLINE -> underlineStart
      EnrichedSpans.STRIKETHROUGH -> strikethroughStart
      EnrichedSpans.INLINE_CODE -> inlineCodeStart
      EnrichedSpans.H1 -> h1Start
      EnrichedSpans.H2 -> h2Start
      EnrichedSpans.H3 -> h3Start
      EnrichedSpans.H4 -> h4Start
      EnrichedSpans.H5 -> h5Start
      EnrichedSpans.H6 -> h6Start
      EnrichedSpans.CODE_BLOCK -> codeBlockStart
      EnrichedSpans.BLOCK_QUOTE -> blockQuoteStart
      EnrichedSpans.ORDERED_LIST -> orderedListStart
      EnrichedSpans.UNORDERED_LIST -> unorderedListStart
      EnrichedSpans.LINK -> linkStart
      EnrichedSpans.IMAGE -> imageStart
      EnrichedSpans.MENTION -> mentionStart
      else -> null
    }

    return start
  }

  fun setStart(
    name: String,
    start: Int?,
  ) {
    when (name) {
      EnrichedSpans.BOLD -> setBoldStart(start)
      EnrichedSpans.ITALIC -> setItalicStart(start)
      EnrichedSpans.UNDERLINE -> setUnderlineStart(start)
      EnrichedSpans.STRIKETHROUGH -> setStrikethroughStart(start)
      EnrichedSpans.INLINE_CODE -> setInlineCodeStart(start)
      EnrichedSpans.H1 -> setH1Start(start)
      EnrichedSpans.H2 -> setH2Start(start)
      EnrichedSpans.H3 -> setH3Start(start)
      EnrichedSpans.H4 -> setH4Start(start)
      EnrichedSpans.H5 -> setH5Start(start)
      EnrichedSpans.H6 -> setH6Start(start)
      EnrichedSpans.CODE_BLOCK -> setCodeBlockStart(start)
      EnrichedSpans.BLOCK_QUOTE -> setBlockQuoteStart(start)
      EnrichedSpans.ORDERED_LIST -> setOrderedListStart(start)
      EnrichedSpans.UNORDERED_LIST -> setUnorderedListStart(start)
      EnrichedSpans.LINK -> setLinkStart(start)
      EnrichedSpans.IMAGE -> setImageStart(start)
      EnrichedSpans.MENTION -> setMentionStart(start)
    }
  }

  private fun emitStateChangeEvent() {
    val payload: WritableMap = Arguments.createMap()
    payload.putBoolean("isBold", boldStart != null)
    payload.putBoolean("isItalic", italicStart != null)
    payload.putBoolean("isUnderline", underlineStart != null)
    payload.putBoolean("isStrikeThrough", strikethroughStart != null)
    payload.putBoolean("isInlineCode", inlineCodeStart != null)
    payload.putBoolean("isH1", h1Start != null)
    payload.putBoolean("isH2", h2Start != null)
    payload.putBoolean("isH3", h3Start != null)
    payload.putBoolean("isH4", h4Start != null)
    payload.putBoolean("isH5", h5Start != null)
    payload.putBoolean("isH6", h6Start != null)
    payload.putBoolean("isCodeBlock", codeBlockStart != null)
    payload.putBoolean("isBlockQuote", blockQuoteStart != null)
    payload.putBoolean("isOrderedList", orderedListStart != null)
    payload.putBoolean("isUnorderedList", unorderedListStart != null)
    payload.putBoolean("isLink", linkStart != null)
    payload.putBoolean("isImage", imageStart != null)
    payload.putBoolean("isMention", mentionStart != null)

    // Do not emit event if payload is the same
    if (previousPayload == payload) {
      return
    }

    previousPayload =
      Arguments.createMap().apply {
        merge(payload)
      }

    val context = view.context as ReactContext
    val surfaceId = UIManagerHelper.getSurfaceId(context)
    val dispatcher = UIManagerHelper.getEventDispatcherForReactTag(context, view.id)
    dispatcher?.dispatchEvent(
      OnChangeStateEvent(
        surfaceId,
        view.id,
        payload,
        view.experimentalSynchronousEvents,
      ),
    )
  }

  companion object {
    const val NAME = "ReactNativeEnrichedView"
  }
}
