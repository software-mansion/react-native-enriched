package com.swmansion.reactnativerichtexteditor

import android.content.Context
import com.facebook.react.bridge.ReadableMap
import com.facebook.react.module.annotations.ReactModule
import com.facebook.react.uimanager.ReactStylesDiffMap
import com.facebook.react.uimanager.SimpleViewManager
import com.facebook.react.uimanager.StateWrapper
import com.facebook.react.uimanager.ThemedReactContext
import com.facebook.react.uimanager.ViewDefaults
import com.facebook.react.uimanager.ViewManagerDelegate
import com.facebook.react.uimanager.ViewProps
import com.facebook.react.uimanager.annotations.ReactProp
import com.facebook.react.viewmanagers.ReactNativeRichTextEditorViewManagerInterface
import com.facebook.react.viewmanagers.ReactNativeRichTextEditorViewManagerDelegate
import com.facebook.yoga.YogaMeasureMode
import com.facebook.yoga.YogaMeasureOutput
import com.swmansion.reactnativerichtexteditor.events.OnChangeHtmlEvent
import com.swmansion.reactnativerichtexteditor.events.OnChangeStateEvent
import com.swmansion.reactnativerichtexteditor.events.OnChangeTextEvent
import com.swmansion.reactnativerichtexteditor.events.OnLinkDetectedEvent
import com.swmansion.reactnativerichtexteditor.events.OnMentionEvent
import com.swmansion.reactnativerichtexteditor.events.OnPressLinkEvent
import com.swmansion.reactnativerichtexteditor.events.OnPressMentionEvent
import com.swmansion.reactnativerichtexteditor.spans.EditorSpans

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
     map.put(OnChangeTextEvent.EVENT_NAME, mapOf("registrationName" to OnChangeTextEvent.EVENT_NAME))
     map.put(OnChangeHtmlEvent.EVENT_NAME, mapOf("registrationName" to OnChangeHtmlEvent.EVENT_NAME))
     map.put(OnChangeStateEvent.EVENT_NAME, mapOf("registrationName" to OnChangeStateEvent.EVENT_NAME))
     map.put(OnPressLinkEvent.EVENT_NAME, mapOf("registrationName" to OnPressLinkEvent.EVENT_NAME))
     map.put(OnLinkDetectedEvent.EVENT_NAME, mapOf("registrationName" to OnLinkDetectedEvent.EVENT_NAME))
     map.put(OnMentionEvent.EVENT_NAME, mapOf("registrationName" to OnMentionEvent.EVENT_NAME))
     map.put(OnPressMentionEvent.EVENT_NAME, mapOf("registrationName" to OnPressMentionEvent.EVENT_NAME))

     return map
   }

  @ReactProp(name = "defaultValue")
  override fun setDefaultValue(view: ReactNativeRichTextEditorView?, value: String?) {
    view?.setDefaultValue(value)
  }

  @ReactProp(name = ViewProps.COLOR, customType = "Color")
  override fun setColor(view: ReactNativeRichTextEditorView?, color: Int?) {
    view?.setColor(color)
  }

  @ReactProp(name = "fontSize", defaultFloat = ViewDefaults.FONT_SIZE_SP)
  override fun setFontSize(view: ReactNativeRichTextEditorView?, size: Float) {
    view?.setFontSize(size)
  }

  @ReactProp(name = "fontFamily")
  override fun setFontFamily(view: ReactNativeRichTextEditorView?, family: String?) {
    view?.setFontFamily(family)
  }

  @ReactProp(name = "fontWeight")
  override fun setFontWeight(view: ReactNativeRichTextEditorView?, weight: String?) {
    view?.setFontWeight(weight)
  }

  @ReactProp(name = "fontStyle")
  override fun setFontStyle(view: ReactNativeRichTextEditorView?, style: String?) {
    view?.setFontStyle(style)
  }

  override fun onAfterUpdateTransaction(view: ReactNativeRichTextEditorView) {
    super.onAfterUpdateTransaction(view)
    view.updateTypeface()
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

  override fun focus(view: ReactNativeRichTextEditorView?) {
    view?.requestFocus()
  }

  override fun blur(view: ReactNativeRichTextEditorView?) {
    view?.clearFocus()
  }

  override fun toggleBold(view: ReactNativeRichTextEditorView?) {
    view?.verifyAndToggleStyle(EditorSpans.BOLD)
  }

  override fun toggleItalic(view: ReactNativeRichTextEditorView?) {
    view?.verifyAndToggleStyle(EditorSpans.ITALIC)
  }

  override fun toggleUnderline(view: ReactNativeRichTextEditorView?) {
    view?.verifyAndToggleStyle(EditorSpans.UNDERLINE)
  }

  override fun toggleStrikeThrough(view: ReactNativeRichTextEditorView?) {
    view?.verifyAndToggleStyle(EditorSpans.STRIKETHROUGH)
  }

  override fun toggleInlineCode(view: ReactNativeRichTextEditorView?) {
    view?.verifyAndToggleStyle(EditorSpans.INLINE_CODE)
  }

  override fun toggleH1(view: ReactNativeRichTextEditorView?) {
    view?.verifyAndToggleStyle(EditorSpans.H1)
  }

  override fun toggleH2(view: ReactNativeRichTextEditorView?) {
    view?.verifyAndToggleStyle(EditorSpans.H2)
  }

  override fun toggleH3(view: ReactNativeRichTextEditorView?) {
    view?.verifyAndToggleStyle(EditorSpans.H3)
  }

  override fun toggleCodeBlock(view: ReactNativeRichTextEditorView?) {
    view?.verifyAndToggleStyle(EditorSpans.CODE_BLOCK)
  }

  override fun toggleBlockQuote(view: ReactNativeRichTextEditorView?) {
    view?.verifyAndToggleStyle(EditorSpans.BLOCK_QUOTE)
  }

  override fun toggleOrderedList(view: ReactNativeRichTextEditorView?) {
    view?.verifyAndToggleStyle(EditorSpans.ORDERED_LIST)
  }

  override fun toggleUnorderedList(view: ReactNativeRichTextEditorView?) {
    view?.verifyAndToggleStyle(EditorSpans.UNORDERED_LIST)
  }

  override fun addLink(view: ReactNativeRichTextEditorView?, text: String, url: String) {
    view?.addLink(text, url)
  }

  override fun addImage(view: ReactNativeRichTextEditorView?, src: String) {
    view?.addImage(src)
  }

  override fun startMention(view: ReactNativeRichTextEditorView?) {
    view?.startMention()
  }

  override fun addMention(view: ReactNativeRichTextEditorView?, text: String, value: String) {
    view?.addMention(text, value)
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

  companion object {
    const val NAME = "ReactNativeRichTextEditorView"
  }
}
