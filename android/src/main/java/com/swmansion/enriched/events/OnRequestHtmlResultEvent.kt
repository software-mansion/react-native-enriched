package com.swmansion.enriched.events

import com.facebook.react.bridge.Arguments
import com.facebook.react.bridge.WritableMap
import com.facebook.react.uimanager.events.Event

class OnRequestHtmlResultEvent(
  surfaceId: Int,
  viewId: Int,
  private val requestId: Int,
  private val html: String
) : Event<OnRequestHtmlResultEvent>(surfaceId, viewId) {

  override fun getEventName(): String {
    return EVENT_NAME
  }

  override fun getEventData(): WritableMap {
    val eventData: WritableMap = Arguments.createMap()
    eventData.putInt("requestId", requestId)
    eventData.putString("html", html)
    return eventData
  }

  companion object {
    const val EVENT_NAME: String = "onRequestHtmlResult"
  }
}
