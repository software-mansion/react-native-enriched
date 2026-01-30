package com.swmansion.enriched.text.events

import com.facebook.react.bridge.Arguments
import com.facebook.react.bridge.WritableMap
import com.facebook.react.uimanager.events.Event

class OnMentionPressEvent(
  surfaceId: Int,
  viewId: Int,
  private val text: String,
  private val indicator: String,
  private val attributes: Map<String, String>,
) : Event<OnMentionPressEvent>(surfaceId, viewId) {
  override fun getEventName(): String = EVENT_NAME

  override fun getEventData(): WritableMap? {
    val eventData: WritableMap = Arguments.createMap()
    val attrsMap = Arguments.createMap()
    for ((key, value) in attributes) {
      attrsMap.putString(key, value)
    }

    eventData.putString("text", text)
    eventData.putMap("attributes", attrsMap)
    eventData.putString("indicator", indicator)
    return eventData
  }

  companion object {
    const val EVENT_NAME: String = "onMentionPress"
  }
}
