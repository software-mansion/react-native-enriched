package com.swmansion.enriched.events

import android.text.Editable
import com.facebook.react.bridge.Arguments
import com.facebook.react.bridge.WritableMap
import com.facebook.react.uimanager.events.Event

class OnChangeTextEvent(surfaceId: Int, viewId: Int, private val editable: Editable) :
  Event<OnChangeTextEvent>(surfaceId, viewId) {

  override fun getEventName(): String {
    return EVENT_NAME
  }

  override fun getEventData(): WritableMap {
    val eventData: WritableMap = Arguments.createMap()
    val text = editable.toString()
    val normalizedText = text.replace(Regex("\\u200B"), "")
    eventData.putString("value", normalizedText)
    return eventData
  }

  companion object {
    const val EVENT_NAME: String = "onChangeText"
  }
}
