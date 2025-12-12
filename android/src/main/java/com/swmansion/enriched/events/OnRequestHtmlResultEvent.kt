package com.swmansion.enriched.events

import com.facebook.react.bridge.Arguments
import com.facebook.react.bridge.WritableMap
import com.facebook.react.uimanager.events.Event

class OnRequestHtmlResultEvent(
  surfaceId: Int,
  viewId: Int,
  private val requestId: Int,
  private val html: String?,
  private val experimentalSynchronousEvents: Boolean
) : Event<OnRequestHtmlResultEvent>(surfaceId, viewId) {

  override fun getEventName(): String = EVENT_NAME

  override fun getEventData(): WritableMap {
    val eventData: WritableMap = Arguments.createMap()
    eventData.putInt("requestId", requestId)
    if (html != null) {
      eventData.putString("html", html)
    } else {
      eventData.putNull("html")
    }
    return eventData
  }

  override fun experimental_isSynchronous(): Boolean = experimentalSynchronousEvents

  companion object {
    const val EVENT_NAME: String = "onRequestHtmlResult"
  }
}
