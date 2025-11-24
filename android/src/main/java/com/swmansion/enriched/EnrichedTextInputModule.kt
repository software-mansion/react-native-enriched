package com.swmansion.enriched

import com.facebook.react.bridge.ReactApplicationContext
import com.facebook.react.bridge.UiThreadUtil
import com.facebook.react.module.annotations.ReactModule
import com.facebook.react.uimanager.UIManagerHelper
import com.swmansion.enriched.utils.EnrichedParser

@ReactModule(name = EnrichedTextInputModule.NAME)
class EnrichedTextInputModule(val reactContext: ReactApplicationContext) :
  NativeEnrichedTextInputModuleSpec(reactContext) {
  override fun getName(): String = NAME

  override fun getHTMLValue(inputTag: Double): String? {
    UiThreadUtil.assertOnUiThread()
    val reactNode = inputTag.toInt()
    val enrichedInput = getComponent(reactNode)
    return enrichedInput?.getHtmlValue() ?: ""
  }

  private fun getComponent(reactTag: Int): EnrichedTextInputView? {
    return try {
      val uiManager = UIManagerHelper.getUIManagerForReactTag(reactContext, reactTag)
      uiManager?.resolveView(reactTag) as? EnrichedTextInputView
    } catch (_: Throwable) {
      null
    }
  }

  companion object {
    const val NAME = "EnrichedTextInputModule"
  }
}
