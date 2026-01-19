package com.swmansion.enriched.text

import android.content.Context
import com.facebook.react.bridge.ReadableMap
import com.facebook.react.module.annotations.ReactModule
import com.facebook.react.uimanager.SimpleViewManager
import com.facebook.react.uimanager.ThemedReactContext
import com.facebook.react.uimanager.ViewManagerDelegate
import com.facebook.react.viewmanagers.EnrichedTextViewManagerDelegate
import com.facebook.react.viewmanagers.EnrichedTextViewManagerInterface
import com.facebook.yoga.YogaMeasureMode
import com.swmansion.enriched.text.events.OnLinkPress
import com.swmansion.enriched.text.events.OnMentionPress

@ReactModule(name = EnrichedTextViewManager.NAME)
class EnrichedTextViewManager :
  SimpleViewManager<EnrichedTextView>(),
  EnrichedTextViewManagerInterface<EnrichedTextView> {
  private val mDelegate: ViewManagerDelegate<EnrichedTextView> =
    EnrichedTextViewManagerDelegate(this)

  override fun getDelegate(): ViewManagerDelegate<EnrichedTextView>? = mDelegate

  override fun getName(): String = NAME

  public override fun createViewInstance(context: ThemedReactContext): EnrichedTextView = EnrichedTextView(context)

  override fun getExportedCustomDirectEventTypeConstants(): MutableMap<String, Any> {
    val map = mutableMapOf<String, Any>()
    map.put(OnLinkPress.EVENT_NAME, mapOf("registrationName" to OnLinkPress.EVENT_NAME))
    map.put(OnMentionPress.EVENT_NAME, mapOf("registrationName" to OnMentionPress.EVENT_NAME))
    return map
  }

  override fun setText(
    view: EnrichedTextView?,
    value: String?,
  ) {
    view?.setValue(value)
  }

  override fun setColor(
    view: EnrichedTextView?,
    value: Int?,
  ) {
    view?.setColor(value)
  }

  override fun setFontSize(
    view: EnrichedTextView?,
    value: Float,
  ) {
    view?.setFontSize(value)
  }

  override fun setFontFamily(
    view: EnrichedTextView?,
    value: String?,
  ) {
    view?.setFontFamily(value)
  }

  override fun setFontWeight(
    view: EnrichedTextView?,
    value: String?,
  ) {
    view?.setFontWeight(value)
  }

  override fun setFontStyle(
    view: EnrichedTextView?,
    value: String?,
  ) {
    view?.setFontStyle(value)
  }

  override fun setPadding(
    view: EnrichedTextView?,
    left: Int,
    top: Int,
    right: Int,
    bottom: Int,
  ) {
    super.setPadding(view, left, top, right, bottom)

    view?.setPadding(left, top, right, bottom)
  }

  override fun setSelectionColor(
    view: EnrichedTextView?,
    value: Int?,
  ) {
    view?.setSelectionColor(value)
  }

  override fun setSelectable(
    view: EnrichedTextView?,
    value: Boolean,
  ) {
    view?.setTextIsSelectable(value)
  }

  override fun setEllipsizeMode(
    view: EnrichedTextView?,
    value: String?,
  ) {
    view?.setEllipsizeMode(value)
  }

  override fun setNumberOfLines(
    view: EnrichedTextView?,
    value: Int,
  ) {
    view?.setNumberOfLines(value)
  }

  override fun setHtmlStyle(
    view: EnrichedTextView?,
    value: ReadableMap?,
  ) {
    view?.setHtmlStyle(value)
  }

  override fun onAfterUpdateTransaction(view: EnrichedTextView) {
    view.afterUpdateTransaction()
  }

  override fun measure(
    context: Context,
    localData: ReadableMap?,
    props: ReadableMap?,
    state: ReadableMap?,
    width: Float,
    widthMode: YogaMeasureMode?,
    height: Float,
    heightMode: YogaMeasureMode?,
    attachmentsPositions: FloatArray?,
  ): Long = MeasurementStore.getMeasureById(context, width, height, heightMode, props)

  companion object {
    const val NAME = "EnrichedTextView"
  }
}
