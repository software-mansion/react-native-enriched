package com.swmansion.enriched.events

import com.facebook.react.bridge.WritableMap
import com.facebook.react.uimanager.events.Event

class OnChangeStateEvent(surfaceId: Int, viewId: Int, private val state: WritableMap, private val experimentalSynchronousEvents: Boolean) :
  Event<OnChangeStateEvent>(surfaceId, viewId) {

  override fun getEventName(): String {
    return EVENT_NAME
  }

  override fun getEventData(): WritableMap {
    return state
  }

  override fun experimental_isSynchronous(): Boolean {
    return experimentalSynchronousEvents
  }

  companion object {
    const val EVENT_NAME: String = "onChangeState"
  }
}
