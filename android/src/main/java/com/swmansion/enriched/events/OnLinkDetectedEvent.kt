package com.swmansion.enriched.events

import com.facebook.react.bridge.Arguments
import com.facebook.react.bridge.WritableMap
import com.facebook.react.uimanager.events.Event

class OnLinkDetectedEvent(surfaceId: Int, viewId: Int, private val text: String, private val url: String, private val start: Int, private val end: Int) :
  Event<OnLinkDetectedEvent>(surfaceId, viewId) {

  override fun getEventName(): String {
    return EVENT_NAME
  }

  override fun getEventData(): WritableMap {
    val eventData: WritableMap = Arguments.createMap()
    eventData.putString("text", text)
    eventData.putString("url", url)
    eventData.putInt("start", start);
    eventData.putInt("end", end);
    return eventData
  }

  companion object {
    const val EVENT_NAME: String = "onLinkDetected"
  }
}
