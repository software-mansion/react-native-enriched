package com.swmansion.enriched.events

import com.facebook.react.bridge.Arguments
import com.facebook.react.bridge.WritableMap
import com.facebook.react.uimanager.events.Event

class OnColorChangeEvent(
  surfaceId: Int,
  viewId: Int,
  private val experimentalSynchronousEvents: Boolean,
  private val color: String?,
) : Event<OnColorChangeEvent>(surfaceId, viewId) {
  override fun getEventName(): String = EVENT_NAME

  override fun getEventData(): WritableMap {
    val eventData: WritableMap = Arguments.createMap()

    eventData.putString("color", color)

    return eventData
  }

  override fun experimental_isSynchronous(): Boolean = experimentalSynchronousEvents

  companion object {
    const val EVENT_NAME: String = "onColorChangeInSelection"
  }
}
