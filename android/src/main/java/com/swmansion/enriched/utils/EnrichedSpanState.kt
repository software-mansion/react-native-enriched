package com.swmansion.enriched.utils

import com.facebook.react.bridge.Arguments
import com.facebook.react.bridge.ReactContext
import com.facebook.react.bridge.WritableMap
import com.facebook.react.uimanager.UIManagerHelper
import com.facebook.react.uimanager.events.EventDispatcher
import com.swmansion.enriched.EnrichedTextInputView
import com.swmansion.enriched.events.OnChangeStateDeprecatedEvent
import com.swmansion.enriched.events.OnChangeStateEvent
import com.swmansion.enriched.spans.EnrichedSpans

class EnrichedSpanState(
  private val view: EnrichedTextInputView,
) {
  private var previousPayload: WritableMap? = null
  private var previousDeprecatedPayload: WritableMap? = null

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
  var checkboxListStart: Int? = null
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

  fun setCheckboxListStart(start: Int?) {
    this.checkboxListStart = start
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
    val start =
      when (name) {
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
        EnrichedSpans.CHECKBOX_LIST -> checkboxListStart
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
      EnrichedSpans.CHECKBOX_LIST -> setCheckboxListStart(start)
      EnrichedSpans.LINK -> setLinkStart(start)
      EnrichedSpans.IMAGE -> setImageStart(start)
      EnrichedSpans.MENTION -> setMentionStart(start)
    }
  }

  private fun emitStateChangeEvent() {
    val context = view.context as ReactContext
    val surfaceId = UIManagerHelper.getSurfaceId(context)
    val dispatcher = UIManagerHelper.getEventDispatcherForReactTag(context, view.id)

    dispatchDeprecatedPayload(dispatcher, surfaceId)
    dispatchPayload(dispatcher, surfaceId)
  }

  private fun dispatchDeprecatedPayload(
    dispatcher: EventDispatcher?,
    surfaceId: Int,
  ) {
    val deprecatedPayload = Arguments.createMap()
    deprecatedPayload.putBoolean("isBold", boldStart != null)
    deprecatedPayload.putBoolean("isItalic", italicStart != null)
    deprecatedPayload.putBoolean("isUnderline", underlineStart != null)
    deprecatedPayload.putBoolean("isStrikeThrough", strikethroughStart != null)
    deprecatedPayload.putBoolean("isInlineCode", inlineCodeStart != null)
    deprecatedPayload.putBoolean("isH1", h1Start != null)
    deprecatedPayload.putBoolean("isH2", h2Start != null)
    deprecatedPayload.putBoolean("isH3", h3Start != null)
    deprecatedPayload.putBoolean("isH4", h4Start != null)
    deprecatedPayload.putBoolean("isH5", h5Start != null)
    deprecatedPayload.putBoolean("isH6", h6Start != null)
    deprecatedPayload.putBoolean("isCodeBlock", codeBlockStart != null)
    deprecatedPayload.putBoolean("isBlockQuote", blockQuoteStart != null)
    deprecatedPayload.putBoolean("isOrderedList", orderedListStart != null)
    deprecatedPayload.putBoolean("isUnorderedList", unorderedListStart != null)
    deprecatedPayload.putBoolean("isCheckboxList", checkboxListStart != null)
    deprecatedPayload.putBoolean("isLink", linkStart != null)
    deprecatedPayload.putBoolean("isImage", imageStart != null)
    deprecatedPayload.putBoolean("isMention", mentionStart != null)

    if (previousDeprecatedPayload == deprecatedPayload) {
      return
    }

    previousDeprecatedPayload =
      Arguments.createMap().apply {
        merge(deprecatedPayload)
      }

    dispatcher?.dispatchEvent(
      OnChangeStateDeprecatedEvent(
        surfaceId,
        view.id,
        deprecatedPayload,
        view.experimentalSynchronousEvents,
      ),
    )
  }

  private fun dispatchPayload(
    dispatcher: EventDispatcher?,
    surfaceId: Int,
  ) {
    val activeStyles =
      listOfNotNull(
        if (boldStart != null) EnrichedSpans.BOLD else null,
        if (italicStart != null) EnrichedSpans.ITALIC else null,
        if (underlineStart != null) EnrichedSpans.UNDERLINE else null,
        if (strikethroughStart != null) EnrichedSpans.STRIKETHROUGH else null,
        if (inlineCodeStart != null) EnrichedSpans.INLINE_CODE else null,
        if (h1Start != null) EnrichedSpans.H1 else null,
        if (h2Start != null) EnrichedSpans.H2 else null,
        if (h3Start != null) EnrichedSpans.H3 else null,
        if (h4Start != null) EnrichedSpans.H4 else null,
        if (h5Start != null) EnrichedSpans.H5 else null,
        if (h6Start != null) EnrichedSpans.H6 else null,
        if (codeBlockStart != null) EnrichedSpans.CODE_BLOCK else null,
        if (blockQuoteStart != null) EnrichedSpans.BLOCK_QUOTE else null,
        if (orderedListStart != null) EnrichedSpans.ORDERED_LIST else null,
        if (unorderedListStart != null) EnrichedSpans.UNORDERED_LIST else null,
        if (checkboxListStart != null) EnrichedSpans.CHECKBOX_LIST else null,
        if (linkStart != null) EnrichedSpans.LINK else null,
        if (imageStart != null) EnrichedSpans.IMAGE else null,
        if (mentionStart != null) EnrichedSpans.MENTION else null,
      )
    val payload = Arguments.createMap()
    payload.putMap("bold", getStyleState(activeStyles, EnrichedSpans.BOLD))
    payload.putMap("italic", getStyleState(activeStyles, EnrichedSpans.ITALIC))
    payload.putMap("underline", getStyleState(activeStyles, EnrichedSpans.UNDERLINE))
    payload.putMap("strikeThrough", getStyleState(activeStyles, EnrichedSpans.STRIKETHROUGH))
    payload.putMap("inlineCode", getStyleState(activeStyles, EnrichedSpans.INLINE_CODE))
    payload.putMap("h1", getStyleState(activeStyles, EnrichedSpans.H1))
    payload.putMap("h2", getStyleState(activeStyles, EnrichedSpans.H2))
    payload.putMap("h3", getStyleState(activeStyles, EnrichedSpans.H3))
    payload.putMap("h4", getStyleState(activeStyles, EnrichedSpans.H4))
    payload.putMap("h5", getStyleState(activeStyles, EnrichedSpans.H5))
    payload.putMap("h6", getStyleState(activeStyles, EnrichedSpans.H6))
    payload.putMap("codeBlock", getStyleState(activeStyles, EnrichedSpans.CODE_BLOCK))
    payload.putMap("blockQuote", getStyleState(activeStyles, EnrichedSpans.BLOCK_QUOTE))
    payload.putMap("orderedList", getStyleState(activeStyles, EnrichedSpans.ORDERED_LIST))
    payload.putMap("unorderedList", getStyleState(activeStyles, EnrichedSpans.UNORDERED_LIST))
    payload.putMap("link", getStyleState(activeStyles, EnrichedSpans.LINK))
    payload.putMap("image", getStyleState(activeStyles, EnrichedSpans.IMAGE))
    payload.putMap("mention", getStyleState(activeStyles, EnrichedSpans.MENTION))
    payload.putMap("checkboxList", getStyleState(activeStyles, EnrichedSpans.CHECKBOX_LIST))

    // Do not emit event if payload is the same
    if (previousPayload == payload) {
      return
    }

    previousPayload =
      Arguments.createMap().apply {
        merge(payload)
      }
    dispatcher?.dispatchEvent(
      OnChangeStateEvent(
        surfaceId,
        view.id,
        payload,
        view.experimentalSynchronousEvents,
      ),
    )
  }

  private fun getStyleState(
    activeStyles: List<String>,
    type: String,
  ): WritableMap {
    val mergingConfig = EnrichedSpans.getMergingConfigForStyle(type, view.htmlStyle)
    val blockingList = mergingConfig?.blockingStyles
    val conflictingList = mergingConfig?.conflictingStyles

    val state = Arguments.createMap()

    state.putBoolean("isActive", activeStyles.contains(type))

    val isBlocking = blockingList?.any { activeStyles.contains(it) } ?: false
    state.putBoolean("isBlocking", isBlocking)

    val isConflicting = conflictingList?.any { activeStyles.contains(it) } ?: false
    state.putBoolean("isConflicting", isConflicting)

    return state
  }

  companion object {
    const val NAME = "ReactNativeEnrichedView"
  }
}
