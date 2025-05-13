package com.swmansion.reactnativerichtexteditor.events

import com.facebook.react.bridge.Arguments
import com.facebook.react.bridge.WritableMap
import com.facebook.react.uimanager.events.Event

class OnChangeHtmlEvent(surfaceId: Int, viewId: Int, private val html: String) :
  Event<OnChangeHtmlEvent>(surfaceId, viewId) {

  override fun getEventName(): String {
    return EVENT_NAME
  }

  override fun getEventData(): WritableMap {
    val eventData: WritableMap = Arguments.createMap()
    eventData.putString("value", html)

    return eventData
  }

  companion object {
    const val EVENT_NAME: String = "onChangeHtml"
  }
}
