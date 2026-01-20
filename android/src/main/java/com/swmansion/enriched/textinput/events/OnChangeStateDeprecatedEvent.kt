package com.swmansion.enriched.textinput.events

import com.facebook.react.bridge.WritableMap
import com.facebook.react.uimanager.events.Event

class OnChangeStateDeprecatedEvent(
  surfaceId: Int,
  viewId: Int,
  private val state: WritableMap,
  private val experimentalSynchronousEvents: Boolean,
) : Event<OnChangeStateDeprecatedEvent>(surfaceId, viewId) {
  override fun getEventName(): String = EVENT_NAME

  override fun getEventData(): WritableMap = state

  override fun experimental_isSynchronous(): Boolean = experimentalSynchronousEvents

  companion object {
    const val EVENT_NAME: String = "onChangeStateDeprecated"
  }
}
