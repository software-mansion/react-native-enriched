package com.swmansion.reactnativerichtexteditor.events

import com.facebook.react.bridge.Arguments
import com.facebook.react.bridge.WritableMap
import com.facebook.react.uimanager.events.Event
import org.json.JSONObject

class OnPressMentionEvent(surfaceId: Int, viewId: Int, private val text: String, private val attributes: Map<String, String>) :
  Event<OnPressMentionEvent>(surfaceId, viewId) {

  override fun getEventName(): String {
    return EVENT_NAME
  }

  override fun getEventData(): WritableMap {
    val eventData: WritableMap = Arguments.createMap()
    eventData.putString("text", text)
    eventData.putString("attributes", JSONObject(attributes).toString())
    return eventData
  }

  companion object {
    const val EVENT_NAME: String = "onPressMention"
  }
}
