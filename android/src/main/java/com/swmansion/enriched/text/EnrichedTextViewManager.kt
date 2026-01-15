package com.swmansion.enriched.text

import android.content.Context
import android.util.Log
import com.facebook.react.bridge.ReadableMap
import com.facebook.react.module.annotations.ReactModule
import com.facebook.react.uimanager.SimpleViewManager
import com.facebook.react.uimanager.ThemedReactContext
import com.facebook.react.uimanager.ViewManagerDelegate
import com.facebook.react.viewmanagers.EnrichedTextViewManagerDelegate
import com.facebook.react.viewmanagers.EnrichedTextViewManagerInterface
import com.facebook.yoga.YogaMeasureMode

@ReactModule(name = EnrichedTextViewManager.NAME)
class EnrichedTextViewManager :
  SimpleViewManager<EnrichedTextView>(),
  EnrichedTextViewManagerInterface<EnrichedTextView> {
  private val mDelegate: ViewManagerDelegate<EnrichedTextView> =
    EnrichedTextViewManagerDelegate(this)

  override fun getDelegate(): ViewManagerDelegate<EnrichedTextView>? = mDelegate

  override fun getName(): String = NAME

  public override fun createViewInstance(context: ThemedReactContext): EnrichedTextView = EnrichedTextView(context)

  override fun setText(
    view: EnrichedTextView?,
    value: String?,
  ) {
    view?.text = value
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

  override fun onAfterUpdateTransaction(view: EnrichedTextView) {
    view.updateTypeface()
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
