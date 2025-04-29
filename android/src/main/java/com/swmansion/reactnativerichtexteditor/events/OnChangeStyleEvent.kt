package com.swmansion.reactnativerichtexteditor.events

import com.facebook.react.bridge.WritableMap
import com.facebook.react.uimanager.events.Event

class OnChangeStyleEvent(surfaceId: Int, viewId: Int, private val state: WritableMap) :
  Event<OnChangeStyleEvent>(surfaceId, viewId) {

  override fun getEventName(): String {
    return EVENT_NAME
  }

  override fun getEventData(): WritableMap {
    return state
  }

  companion object {
    const val EVENT_NAME: String = "onChangeStyle"
  }
}
