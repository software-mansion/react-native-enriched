package com.swmansion.reactnativerichtexteditor

import com.facebook.react.bridge.Arguments
import com.facebook.react.bridge.WritableMap
import com.facebook.react.uimanager.events.Event

class OnChangeTextEvent(surfaceId: Int, viewId: Int, private val text: String) :
  Event<OnChangeTextEvent>(surfaceId, viewId) {

  override fun getEventName(): String {
    return EVENT_NAME
  }

  override fun getEventData(): WritableMap {
    val eventData: WritableMap = Arguments.createMap()
    eventData.putString("value", text)
    return eventData
  }

  public companion object {
    public const val EVENT_NAME: String = "onChangeText"
  }
}
