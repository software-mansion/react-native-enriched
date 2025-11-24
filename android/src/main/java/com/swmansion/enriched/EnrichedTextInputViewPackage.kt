package com.swmansion.enriched

import com.facebook.react.BaseReactPackage
import com.facebook.react.uimanager.ViewManager
import com.facebook.react.bridge.NativeModule
import com.facebook.react.bridge.ReactApplicationContext
import com.facebook.react.module.model.ReactModuleInfo
import com.facebook.react.module.model.ReactModuleInfoProvider
import java.util.HashMap

class EnrichedTextInputViewPackage : BaseReactPackage() {
  override fun createViewManagers(reactContext: ReactApplicationContext): List<ViewManager<*, *>> {
    return listOf(EnrichedTextInputViewManager())
  }

    override fun getModule(name: String, reactContext: ReactApplicationContext): NativeModule? {
        return if (name == EnrichedTextInputModule.NAME) {
            EnrichedTextInputModule(reactContext)
        } else {
            null
        }
    }

    override fun getReactModuleInfoProvider(): ReactModuleInfoProvider {
        return ReactModuleInfoProvider {
            val moduleMap: MutableMap<String, ReactModuleInfo> = HashMap()
            moduleMap[EnrichedTextInputModule.NAME] = ReactModuleInfo(
              EnrichedTextInputModule.NAME,
              EnrichedTextInputModule.NAME,
              false, // canOverrideExistingModule
              false, // needsEagerInit
              false, // isCxxModule
              true   // isTurboModule
            )
            moduleMap
        }
    }
}