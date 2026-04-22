package com.swmansion.enriched.textinput.events

import com.facebook.react.bridge.Arguments
import com.facebook.react.bridge.WritableMap
import com.facebook.react.uimanager.events.Event

class OnMaxLengthExceededEvent(
  surfaceId: Int,
  viewId: Int,
  private val maxLength: Int,
  private val experimentalSynchronousEvents: Boolean,
) : Event<OnMaxLengthExceededEvent>(surfaceId, viewId) {
  override fun getEventName(): String = EVENT_NAME

  override fun getEventData(): WritableMap {
    val eventData: WritableMap = Arguments.createMap()
    eventData.putInt("maxLength", maxLength)
    return eventData
  }

  override fun experimental_isSynchronous(): Boolean = experimentalSynchronousEvents

  companion object {
    const val EVENT_NAME: String = "onMaxLengthExceeded"
  }
}
