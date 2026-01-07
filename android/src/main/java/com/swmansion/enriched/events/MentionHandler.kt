package com.swmansion.enriched.events

import com.facebook.react.bridge.ReactContext
import com.facebook.react.uimanager.UIManagerHelper
import com.swmansion.enriched.EnrichedTextInputView

class MentionHandler(
  private val view: EnrichedTextInputView,
) {
  private var previousText: String? = null
  private var previousIndicator: String? = null

  fun reset() {
    endMention()
    previousText = null
  }

  fun endMention() {
    val indicator = previousIndicator
    if (indicator == null) return

    emitEvent(indicator, null)
    previousIndicator = null
  }

  fun onMention(
    indicator: String,
    text: String?,
  ) {
    emitEvent(indicator, text)
    previousIndicator = indicator
  }

  private fun emitEvent(
    indicator: String,
    text: String?,
  ) {
    // Do not emit events too often
    if (previousText == text) return

    previousText = text
    val context = view.context as ReactContext
    val surfaceId = UIManagerHelper.getSurfaceId(context)
    val dispatcher = UIManagerHelper.getEventDispatcherForReactTag(context, view.id)
    dispatcher?.dispatchEvent(
      OnMentionEvent(
        surfaceId,
        view.id,
        indicator,
        text,
        view.experimentalSynchronousEvents,
      ),
    )
  }
}
