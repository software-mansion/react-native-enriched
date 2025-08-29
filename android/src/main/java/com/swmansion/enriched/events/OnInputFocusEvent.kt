package com.swmansion.enriched.events

import com.facebook.react.bridge.Arguments
import com.facebook.react.bridge.WritableMap
import com.facebook.react.uimanager.events.Event

class OnInputFocusEvent(surfaceId: Int, viewId: Int) :
  Event<OnInputFocusEvent>(surfaceId, viewId) {

  override fun getEventName(): String {
    return EVENT_NAME
  }

  override fun getEventData(): WritableMap {
    val eventData: WritableMap = Arguments.createMap()

    return eventData
  }

  companion object {
    const val EVENT_NAME: String = "onInputFocus"
  }
}
