package com.swmansion.reactnativerichtexteditor

import com.facebook.react.common.MapBuilder
import com.facebook.react.module.annotations.ReactModule
import com.facebook.react.uimanager.BaseViewManager
import com.facebook.react.uimanager.LayoutShadowNode
import com.facebook.react.uimanager.SimpleViewManager
import com.facebook.react.uimanager.ThemedReactContext
import com.facebook.react.uimanager.ViewManagerDelegate
import com.facebook.react.uimanager.annotations.ReactProp
import com.facebook.react.viewmanagers.ReactNativeRichTextEditorViewManagerInterface
import com.facebook.react.viewmanagers.ReactNativeRichTextEditorViewManagerDelegate

@ReactModule(name = ReactNativeRichTextEditorViewManager.NAME)
class ReactNativeRichTextEditorViewManager : BaseViewManager<ReactNativeRichTextEditorView, LayoutShadowNode>(),
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

  override fun createShadowNodeInstance(): LayoutShadowNode {
    return LayoutShadowNode()
  }

  override fun getShadowNodeClass(): Class<LayoutShadowNode> {
    return LayoutShadowNode::class.java
  }

  public override fun updateExtraData(editor: ReactNativeRichTextEditorView, extraData: Any?) {
    TODO("Not yet implemented")
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
