package com.swmansion.reactnativerichtexteditor.events

import com.facebook.react.bridge.Arguments
import com.facebook.react.bridge.WritableMap
import com.facebook.react.uimanager.events.Event

class OnMentionEvent(surfaceId: Int, viewId: Int, private val text: String?) : Event<OnMentionEvent>(surfaceId, viewId) {

  override fun getEventName(): String {
    return EVENT_NAME
  }

  override fun getEventData(): WritableMap? {
    val eventData: WritableMap = Arguments.createMap()

    if (text == null) {
      eventData.putNull("text")
    } else {
      eventData.putString("text", text)
    }

    return eventData
  }

  companion object {
    const val EVENT_NAME: String = "onMention"
  }
}
