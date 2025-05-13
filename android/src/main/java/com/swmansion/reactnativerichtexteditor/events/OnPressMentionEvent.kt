package com.swmansion.reactnativerichtexteditor.events

import com.facebook.react.bridge.Arguments
import com.facebook.react.bridge.WritableMap
import com.facebook.react.uimanager.events.Event

class OnPressMentionEvent(surfaceId: Int, viewId: Int, private val text: String, private val value: String) :
  Event<OnPressMentionEvent>(surfaceId, viewId) {

  override fun getEventName(): String {
    return EVENT_NAME
  }

  override fun getEventData(): WritableMap {
    val eventData: WritableMap = Arguments.createMap()
    eventData.putString("text", text)
    eventData.putString("value", value)
    return eventData
  }

  companion object {
    const val EVENT_NAME: String = "onPressMention"
  }
}
