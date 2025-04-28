package com.swmansion.reactnativerichtexteditor

import android.content.Context
import com.facebook.react.bridge.ReadableMap
import com.facebook.react.module.annotations.ReactModule
import com.facebook.react.uimanager.ReactStylesDiffMap
import com.facebook.react.uimanager.SimpleViewManager
import com.facebook.react.uimanager.StateWrapper
import com.facebook.react.uimanager.ThemedReactContext
import com.facebook.react.uimanager.ViewManagerDelegate
import com.facebook.react.uimanager.annotations.ReactProp
import com.facebook.react.viewmanagers.ReactNativeRichTextEditorViewManagerInterface
import com.facebook.react.viewmanagers.ReactNativeRichTextEditorViewManagerDelegate
import com.facebook.yoga.YogaMeasureMode
import com.facebook.yoga.YogaMeasureOutput

@ReactModule(name = ReactNativeRichTextEditorViewManager.NAME)
class ReactNativeRichTextEditorViewManager : SimpleViewManager<ReactNativeRichTextEditorView>(),
  ReactNativeRichTextEditorViewManagerInterface<ReactNativeRichTextEditorView> {
  private val mDelegate: ViewManagerDelegate<ReactNativeRichTextEditorView>
  private var view: ReactNativeRichTextEditorView? = null

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
    val view = ReactNativeRichTextEditorView(context)
    this.view = view

    return view
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
     val map = mutableMapOf<String, Any>()
     map.put("onChangeText", mapOf("registrationName" to "onChangeText"))

     return map
   }

  @ReactProp(name = "defaultValue")
  override fun setDefaultValue(view: ReactNativeRichTextEditorView?, value: String?) {
    view?.setDefaultValue(value)
  }

  @ReactProp(name = "value")
  override fun setValue(view: ReactNativeRichTextEditorView?, value: String?) {
    // Our component is not controlled, however we are setting value to explicitly tell Yoga to recalculate layout
    // See https://github.com/facebook/react-native/issues/17968
  }

  override fun setPadding(
    view: ReactNativeRichTextEditorView?,
    left: Int,
    top: Int,
    right: Int,
    bottom: Int
  ) {
    super.setPadding(view, left, top, right, bottom)

    view?.setPadding(left, top, right, bottom)
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
    attachmentsPositions: FloatArray?
  ): Long {
    val size = this.view?.measureSize(width)

    if (size != null) {
      return YogaMeasureOutput.make(size.first, size.second)
    }

    return YogaMeasureOutput.make(0, 0)
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
