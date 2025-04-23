package com.swmansion.reactnativerichtexteditor

import com.facebook.react.common.MapBuilder
import com.facebook.react.module.annotations.ReactModule
import com.facebook.react.uimanager.PixelUtil
import com.facebook.react.uimanager.ReactStylesDiffMap
import com.facebook.react.uimanager.SimpleViewManager
import com.facebook.react.uimanager.StateWrapper
import com.facebook.react.uimanager.ThemedReactContext
import com.facebook.react.uimanager.ViewManagerDelegate
import com.facebook.react.uimanager.annotations.ReactProp
import com.facebook.react.viewmanagers.ReactNativeRichTextEditorViewManagerInterface
import com.facebook.react.viewmanagers.ReactNativeRichTextEditorViewManagerDelegate

@ReactModule(name = ReactNativeRichTextEditorViewManager.NAME)
class ReactNativeRichTextEditorViewManager : SimpleViewManager<ReactNativeRichTextEditorView>(),
  ReactNativeRichTextEditorViewManagerInterface<ReactNativeRichTextEditorView> {
  private val mDelegate: ViewManagerDelegate<ReactNativeRichTextEditorView>

  init {
    mDelegate = ReactNativeRichTextEditorViewManagerDelegate(this)
  }

  override fun getDelegate(): ViewManagerDelegate<ReactNativeRichTextEditorView>? {
    return mDelegate
  }

  override fun getName(): String {
    return NAME
  }

  public override fun createViewInstance(context: ThemedReactContext): ReactNativeRichTextEditorView {
    return ReactNativeRichTextEditorView(context)
  }

  override fun updateState(
    view: ReactNativeRichTextEditorView,
    props: ReactStylesDiffMap?,
    stateWrapper: StateWrapper?
  ): Any? {
    view.setStateWrapper(stateWrapper)

    return super.updateState(view, props, stateWrapper)
  }

   override fun getExportedCustomDirectEventTypeConstants(): MutableMap<String, Any> {
     return MapBuilder.of(
              "onChangeText",
              MapBuilder.of("registrationName", "onChangeText"),
      )
   }

  @ReactProp(name = "defaultValue")
  override fun setDefaultValue(view: ReactNativeRichTextEditorView?, value: String?) {
    view?.setDefaultValue(value)
  }

  @ReactProp(name = "width")
  override fun setWidth(view: ReactNativeRichTextEditorView?, width: Int) {
    // TODO: this should be applied through styles
    view?.mWidth = PixelUtil.toPixelFromSP(width.toDouble()).toInt()
    view?.width = PixelUtil.toPixelFromSP(width.toDouble()).toInt()
  }

  override fun focus(view: ReactNativeRichTextEditorView?) {
    view?.requestFocus()
  }

  override fun blur(view: ReactNativeRichTextEditorView?) {
    view?.clearFocus()
  }

  companion object {
    const val NAME = "ReactNativeRichTextEditorView"
  }
}
