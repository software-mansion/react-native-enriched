package com.swmansion.enriched.events

import com.facebook.react.bridge.Arguments
import com.facebook.react.bridge.WritableMap
import com.facebook.react.uimanager.events.Event

class OnMentionEvent(surfaceId: Int, viewId: Int, private val indicator: String, private val text: String?, private val experimentalSynchronousEvents: Boolean) : Event<OnMentionEvent>(surfaceId, viewId) {

  override fun getEventName(): String {
    return EVENT_NAME
  }

  override fun getEventData(): WritableMap? {
    val eventData: WritableMap = Arguments.createMap()
    eventData.putString("indicator", indicator)

    if (text == null) {
      eventData.putNull("text")
    } else {
      eventData.putString("text", text)
    }

    return eventData
  }

  override fun experimental_isSynchronous(): Boolean {
    return experimentalSynchronousEvents
  }

  companion object {
    const val EVENT_NAME: String = "onMention"
  }
}
