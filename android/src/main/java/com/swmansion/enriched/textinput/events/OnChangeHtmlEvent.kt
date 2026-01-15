package com.swmansion.enriched.textinput.events

import com.facebook.react.bridge.Arguments
import com.facebook.react.bridge.WritableMap
import com.facebook.react.uimanager.events.Event

class OnChangeHtmlEvent(
  surfaceId: Int,
  viewId: Int,
  private val html: String,
  private val experimentalSynchronousEvents: Boolean,
) : Event<OnChangeHtmlEvent>(surfaceId, viewId) {
  override fun getEventName(): String = EVENT_NAME

  override fun getEventData(): WritableMap {
    val eventData: WritableMap = Arguments.createMap()
    eventData.putString("value", html)

    return eventData
  }

  override fun experimental_isSynchronous(): Boolean = experimentalSynchronousEvents

  companion object {
    const val EVENT_NAME: String = "onChangeHtml"
  }
}
