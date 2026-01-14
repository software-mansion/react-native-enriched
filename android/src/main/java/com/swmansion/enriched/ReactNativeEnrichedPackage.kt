package com.swmansion.enriched

import com.facebook.react.ReactPackage
import com.facebook.react.bridge.NativeModule
import com.facebook.react.bridge.ReactApplicationContext
import com.facebook.react.uimanager.ViewManager
import com.swmansion.enriched.common.ResourceManager
import com.swmansion.enriched.text.EnrichedTextViewManager
import com.swmansion.enriched.textinput.EnrichedTextInputViewManager
import java.util.ArrayList

class ReactNativeEnrichedPackage : ReactPackage {
  override fun createViewManagers(reactContext: ReactApplicationContext): List<ViewManager<*, *>> {
    ResourceManager.init(reactContext.applicationContext)
    val viewManagers: MutableList<ViewManager<*, *>> = ArrayList()
    viewManagers.add(EnrichedTextInputViewManager())
    viewManagers.add(EnrichedTextViewManager())
    return viewManagers
  }

  override fun createNativeModules(reactContext: ReactApplicationContext): List<NativeModule> = emptyList()
}
