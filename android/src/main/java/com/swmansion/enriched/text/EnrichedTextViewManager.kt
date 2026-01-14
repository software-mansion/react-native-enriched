package com.swmansion.enriched.text

import com.facebook.react.module.annotations.ReactModule
import com.facebook.react.uimanager.SimpleViewManager
import com.facebook.react.uimanager.ThemedReactContext
import com.facebook.react.uimanager.ViewManagerDelegate
import com.facebook.react.viewmanagers.EnrichedTextViewManagerDelegate
import com.facebook.react.viewmanagers.EnrichedTextViewManagerInterface

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

  companion object {
    const val NAME = "EnrichedTextView"
  }
}
