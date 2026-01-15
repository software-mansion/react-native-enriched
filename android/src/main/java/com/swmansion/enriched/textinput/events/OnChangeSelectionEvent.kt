package com.swmansion.enriched.textinput.events

import com.facebook.react.bridge.Arguments
import com.facebook.react.bridge.WritableMap
import com.facebook.react.uimanager.events.Event

class OnChangeSelectionEvent(
  surfaceId: Int,
  viewId: Int,
  private val text: String,
  private val start: Int,
  private val end: Int,
  private val experimentalSynchronousEvents: Boolean,
) : Event<OnChangeSelectionEvent>(surfaceId, viewId) {
  override fun getEventName(): String = EVENT_NAME

  override fun getEventData(): WritableMap {
    val eventData: WritableMap = Arguments.createMap()
    eventData.putString("text", text)
    eventData.putInt("start", start)
    eventData.putInt("end", end)
    return eventData
  }

  override fun experimental_isSynchronous(): Boolean = experimentalSynchronousEvents

  companion object {
    const val EVENT_NAME: String = "onChangeSelection"
  }
}
