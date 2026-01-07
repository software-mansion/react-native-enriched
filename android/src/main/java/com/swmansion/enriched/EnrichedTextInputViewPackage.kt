package com.swmansion.enriched

import com.facebook.react.ReactPackage
import com.facebook.react.bridge.NativeModule
import com.facebook.react.bridge.ReactApplicationContext
import com.facebook.react.uimanager.ViewManager
import com.swmansion.enriched.utils.ResourceManager
import java.util.ArrayList

class EnrichedTextInputViewPackage : ReactPackage {
  override fun createViewManagers(reactContext: ReactApplicationContext): List<ViewManager<*, *>> {
    ResourceManager.init(reactContext.applicationContext)
    val viewManagers: MutableList<ViewManager<*, *>> = ArrayList()
    viewManagers.add(EnrichedTextInputViewManager())
    return viewManagers
  }

  override fun createNativeModules(reactContext: ReactApplicationContext): List<NativeModule> = emptyList()
}
