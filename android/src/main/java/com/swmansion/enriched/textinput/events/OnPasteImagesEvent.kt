package com.swmansion.enriched.textinput.events

import com.facebook.react.bridge.Arguments
import com.facebook.react.bridge.WritableArray
import com.facebook.react.bridge.WritableMap
import com.facebook.react.uimanager.events.Event

data class PastedImage(
  val uri: String,
  val type: String,
  val width: Double,
  val height: Double,
)

class OnPasteImagesEvent(
  surfaceId: Int,
  viewId: Int,
  private val images: List<PastedImage>,
  private val experimentalSynchronousEvents: Boolean,
) : Event<OnPasteImagesEvent>(surfaceId, viewId) {
  override fun getEventName(): String = EVENT_NAME

  override fun getEventData(): WritableMap {
    val imagesArray: WritableArray = Arguments.createArray()

    for (image in images) {
      val imageMap = Arguments.createMap()
      imageMap.putString("uri", image.uri)
      imageMap.putString("type", image.type)
      imageMap.putDouble("width", image.width)
      imageMap.putDouble("height", image.height)

      imagesArray.pushMap(imageMap)
    }

    val eventData: WritableMap = Arguments.createMap()
    eventData.putArray("images", imagesArray)

    return eventData
  }

  override fun experimental_isSynchronous(): Boolean = experimentalSynchronousEvents

  companion object {
    const val EVENT_NAME: String = "onPasteImages"
  }
}
