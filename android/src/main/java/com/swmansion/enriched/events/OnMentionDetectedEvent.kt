package com.swmansion.enriched.events

import com.facebook.react.bridge.Arguments
import com.facebook.react.bridge.WritableMap
import com.facebook.react.uimanager.events.Event

class OnMentionDetectedEvent(surfaceId: Int, viewId: Int, private val text: String, private val indicator: String, private val payload: String) :
  Event<OnMentionDetectedEvent>(surfaceId, viewId) {

  override fun getEventName(): String {
    return EVENT_NAME
  }

  override fun getEventData(): WritableMap {
    val eventData: WritableMap = Arguments.createMap()
    eventData.putString("text", text)
    eventData.putString("indicator", indicator)
    eventData.putString("payload", payload)
    return eventData
  }

  companion object {
    const val EVENT_NAME: String = "onMentionDetected"
  }
}
