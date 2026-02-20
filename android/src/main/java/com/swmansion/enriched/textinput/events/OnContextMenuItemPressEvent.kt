package com.swmansion.enriched.textinput.events

import com.facebook.react.bridge.Arguments
import com.facebook.react.bridge.WritableMap
import com.facebook.react.uimanager.events.Event

class OnContextMenuItemPressEvent(
  surfaceId: Int,
  viewId: Int,
  private val index: Int,
  private val selectedText: String,
  private val selectionStart: Int,
  private val selectionEnd: Int,
  private val experimentalSynchronousEvents: Boolean,
) : Event<OnContextMenuItemPressEvent>(surfaceId, viewId) {
  override fun getEventName(): String = EVENT_NAME

  override fun getEventData(): WritableMap {
    val eventData: WritableMap = Arguments.createMap()
    eventData.putInt("index", index)
    eventData.putString("selectedText", selectedText)
    eventData.putInt("selectionStart", selectionStart)
    eventData.putInt("selectionEnd", selectionEnd)
    return eventData
  }

  override fun experimental_isSynchronous(): Boolean = experimentalSynchronousEvents

  companion object {
    const val EVENT_NAME: String = "onContextMenuItemPress"
  }
}
