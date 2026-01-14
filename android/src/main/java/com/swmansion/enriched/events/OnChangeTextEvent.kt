package com.swmansion.enriched.events

import android.text.Editable
import com.facebook.react.bridge.Arguments
import com.facebook.react.bridge.WritableMap
import com.facebook.react.uimanager.events.Event
import com.swmansion.enriched.utils.EnrichedConstants

class OnChangeTextEvent(
  surfaceId: Int,
  viewId: Int,
  private val editable: Editable,
  private val experimentalSynchronousEvents: Boolean,
) : Event<OnChangeTextEvent>(surfaceId, viewId) {
  override fun getEventName(): String = EVENT_NAME

  override fun getEventData(): WritableMap {
    val eventData: WritableMap = Arguments.createMap()
    val text = editable.toString()
    val normalizedText = text.replace(Regex(EnrichedConstants.ZWS.toString()), "")
    eventData.putString("value", normalizedText)
    return eventData
  }

  override fun experimental_isSynchronous(): Boolean = experimentalSynchronousEvents

  companion object {
    const val EVENT_NAME: String = "onChangeText"
  }
}
