package com.swmansion.enriched

import android.content.Context
import com.facebook.react.bridge.ReadableArray
import com.facebook.react.bridge.ReadableMap
import com.facebook.react.module.annotations.ReactModule
import com.facebook.react.uimanager.ReactStylesDiffMap
import com.facebook.react.uimanager.SimpleViewManager
import com.facebook.react.uimanager.StateWrapper
import com.facebook.react.uimanager.ThemedReactContext
import com.facebook.react.uimanager.ViewDefaults
import com.facebook.react.uimanager.ViewManagerDelegate
import com.facebook.react.uimanager.annotations.ReactProp
import com.facebook.react.viewmanagers.EnrichedTextInputViewManagerDelegate
import com.facebook.react.viewmanagers.EnrichedTextInputViewManagerInterface
import com.facebook.yoga.YogaMeasureMode
import com.facebook.yoga.YogaMeasureOutput
import com.swmansion.enriched.events.OnInputBlurEvent
import com.swmansion.enriched.events.OnChangeHtmlEvent
import com.swmansion.enriched.events.OnChangeSelectionEvent
import com.swmansion.enriched.events.OnChangeStateEvent
import com.swmansion.enriched.events.OnChangeTextEvent
import com.swmansion.enriched.events.OnInputFocusEvent
import com.swmansion.enriched.events.OnLinkDetectedEvent
import com.swmansion.enriched.events.OnMentionDetectedEvent
import com.swmansion.enriched.events.OnMentionEvent
import com.swmansion.enriched.spans.EnrichedSpans
import com.swmansion.enriched.styles.HtmlStyle
import com.swmansion.enriched.utils.jsonStringToStringMap

@ReactModule(name = EnrichedTextInputViewManager.NAME)
class EnrichedTextInputViewManager : SimpleViewManager<EnrichedTextInputView>(),
  EnrichedTextInputViewManagerInterface<EnrichedTextInputView> {
  private val mDelegate: ViewManagerDelegate<EnrichedTextInputView>
  private var view: EnrichedTextInputView? = null

  init {
    mDelegate = EnrichedTextInputViewManagerDelegate(this)
  }

  override fun getDelegate(): ViewManagerDelegate<EnrichedTextInputView>? {
    return mDelegate
  }

  override fun getName(): String {
    return NAME
  }

  public override fun createViewInstance(context: ThemedReactContext): EnrichedTextInputView {
    val view = EnrichedTextInputView(context)
    this.view = view

    return view
  }

  override fun updateState(
    view: EnrichedTextInputView,
    props: ReactStylesDiffMap?,
    stateWrapper: StateWrapper?
  ): Any? {
    view.stateWrapper = stateWrapper
    return super.updateState(view, props, stateWrapper)
  }

   override fun getExportedCustomDirectEventTypeConstants(): MutableMap<String, Any> {
     val map = mutableMapOf<String, Any>()
     map.put(OnInputFocusEvent.EVENT_NAME, mapOf("registrationName" to OnInputFocusEvent.EVENT_NAME))
     map.put(OnInputBlurEvent.EVENT_NAME, mapOf("registrationName" to OnInputBlurEvent.EVENT_NAME))
     map.put(OnChangeTextEvent.EVENT_NAME, mapOf("registrationName" to OnChangeTextEvent.EVENT_NAME))
     map.put(OnChangeHtmlEvent.EVENT_NAME, mapOf("registrationName" to OnChangeHtmlEvent.EVENT_NAME))
     map.put(OnChangeStateEvent.EVENT_NAME, mapOf("registrationName" to OnChangeStateEvent.EVENT_NAME))
     map.put(OnLinkDetectedEvent.EVENT_NAME, mapOf("registrationName" to OnLinkDetectedEvent.EVENT_NAME))
     map.put(OnMentionDetectedEvent.EVENT_NAME, mapOf("registrationName" to OnMentionDetectedEvent.EVENT_NAME))
     map.put(OnMentionEvent.EVENT_NAME, mapOf("registrationName" to OnMentionEvent.EVENT_NAME))
     map.put(OnChangeSelectionEvent.EVENT_NAME, mapOf("registrationName" to OnChangeSelectionEvent.EVENT_NAME))

     return map
   }

  @ReactProp(name = "defaultValue")
  override fun setDefaultValue(view: EnrichedTextInputView?, value: String?) {
    view?.setValue(value)
  }

  @ReactProp(name = "placeholder")
  override fun setPlaceholder(view: EnrichedTextInputView?, value: String?) {
    view?.setPlaceholder(value)
  }

  @ReactProp(name = "placeholderTextColor", customType = "Color")
  override fun setPlaceholderTextColor(view: EnrichedTextInputView?, color: Int?) {
    view?.setPlaceholderTextColor(color)
  }

  @ReactProp(name = "cursorColor", customType = "Color")
  override fun setCursorColor(view: EnrichedTextInputView?, color: Int?) {
    view?.setCursorColor(color)
  }

  @ReactProp(name = "selectionColor", customType = "Color")
  override fun setSelectionColor(view: EnrichedTextInputView?, color: Int?) {
    view?.setSelectionColor(color)
  }

  @ReactProp(name = "autoFocus", defaultBoolean = false)
  override fun setAutoFocus(view: EnrichedTextInputView?, autoFocus: Boolean) {
    view?.setAutoFocus(autoFocus)
  }

  @ReactProp(name = "editable", defaultBoolean = true)
  override fun setEditable(view: EnrichedTextInputView?, editable: Boolean) {
    view?.isEnabled = editable
  }

  @ReactProp(name = "mentionIndicators")
  override fun setMentionIndicators(view: EnrichedTextInputView?, indicators: ReadableArray?) {
    if (indicators == null) return

    val indicatorsList = mutableListOf<String>()
    for (i in 0 until indicators.size()) {
      val stringValue = indicators.getString(i) ?: continue
      indicatorsList.add(stringValue)
    }

    val indicatorsArray = indicatorsList.toTypedArray()
    view?.parametrizedStyles?.mentionIndicators = indicatorsArray
  }

  @ReactProp(name = "htmlStyle")
  override fun setHtmlStyle(view: EnrichedTextInputView?, style: ReadableMap?) {
    view?.htmlStyle = HtmlStyle(view, style)
  }

  @ReactProp(name = "color", customType = "Color")
  override fun setColor(view: EnrichedTextInputView?, color: Int?) {
    view?.setColor(color)
  }

  @ReactProp(name = "fontSize", defaultFloat = ViewDefaults.FONT_SIZE_SP)
  override fun setFontSize(view: EnrichedTextInputView?, size: Float) {
    view?.setFontSize(size)
  }

  @ReactProp(name = "fontFamily")
  override fun setFontFamily(view: EnrichedTextInputView?, family: String?) {
    view?.setFontFamily(family)
  }

  @ReactProp(name = "fontWeight")
  override fun setFontWeight(view: EnrichedTextInputView?, weight: String?) {
    view?.setFontWeight(weight)
  }

  @ReactProp(name = "fontStyle")
  override fun setFontStyle(view: EnrichedTextInputView?, style: String?) {
    view?.setFontStyle(style)
  }

  override fun onAfterUpdateTransaction(view: EnrichedTextInputView) {
    super.onAfterUpdateTransaction(view)
    view.updateTypeface()
  }

  override fun setPadding(
    view: EnrichedTextInputView?,
    left: Int,
    top: Int,
    right: Int,
    bottom: Int
  ) {
    super.setPadding(view, left, top, right, bottom)

    view?.setPadding(left, top, right, bottom)
  }

  @ReactProp(name = "isOnChangeHtmlSet", defaultBoolean = true)
  override fun setIsOnChangeHtmlSet(view: EnrichedTextInputView?, value: Boolean) {
    // this prop isn't used on Android as of now, but the setter must be present
  }

  override fun setAutoCapitalize(view: EnrichedTextInputView?, flag: String?) {
    view?.setAutoCapitalize(flag)
  }

  override fun setAndroidExperimentalSynchronousEvents(
    view: EnrichedTextInputView?,
    value: Boolean
  ) {
    view?.experimentalSynchronousEvents = value
  }

  override fun focus(view: EnrichedTextInputView?) {
    view?.requestFocusProgrammatically()
  }

  override fun blur(view: EnrichedTextInputView?) {
    view?.clearFocus()
  }

  override fun setValue(view: EnrichedTextInputView?, text: String) {
    view?.setValue(text)
  }

  override fun toggleBold(view: EnrichedTextInputView?) {
    view?.verifyAndToggleStyle(EnrichedSpans.BOLD)
  }

  override fun toggleItalic(view: EnrichedTextInputView?) {
    view?.verifyAndToggleStyle(EnrichedSpans.ITALIC)
  }

  override fun toggleUnderline(view: EnrichedTextInputView?) {
    view?.verifyAndToggleStyle(EnrichedSpans.UNDERLINE)
  }

  override fun toggleStrikeThrough(view: EnrichedTextInputView?) {
    view?.verifyAndToggleStyle(EnrichedSpans.STRIKETHROUGH)
  }

  override fun toggleInlineCode(view: EnrichedTextInputView?) {
    view?.verifyAndToggleStyle(EnrichedSpans.INLINE_CODE)
  }

  override fun toggleH1(view: EnrichedTextInputView?) {
    view?.verifyAndToggleStyle(EnrichedSpans.H1)
  }

  override fun toggleH2(view: EnrichedTextInputView?) {
    view?.verifyAndToggleStyle(EnrichedSpans.H2)
  }

  override fun toggleH3(view: EnrichedTextInputView?) {
    view?.verifyAndToggleStyle(EnrichedSpans.H3)
  }

  override fun toggleCodeBlock(view: EnrichedTextInputView?) {
    view?.verifyAndToggleStyle(EnrichedSpans.CODE_BLOCK)
  }

  override fun toggleBlockQuote(view: EnrichedTextInputView?) {
    view?.verifyAndToggleStyle(EnrichedSpans.BLOCK_QUOTE)
  }

  override fun toggleOrderedList(view: EnrichedTextInputView?) {
    view?.verifyAndToggleStyle(EnrichedSpans.ORDERED_LIST)
  }

  override fun toggleUnorderedList(view: EnrichedTextInputView?) {
    view?.verifyAndToggleStyle(EnrichedSpans.UNORDERED_LIST)
  }

  override fun addLink(view: EnrichedTextInputView?, start: Int, end: Int, text: String, url: String) {
    view?.addLink(start, end, text, url)
  }

  override fun addImage(view: EnrichedTextInputView?, src: String) {
    view?.addImage(src)
  }

  override fun startMention(view: EnrichedTextInputView?, indicator: String) {
    view?.startMention(indicator)
  }

  override fun addMention(view: EnrichedTextInputView?, indicator: String, text: String, payload: String) {
    val attributes = jsonStringToStringMap(payload)
    view?.addMention(text, indicator, attributes)
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
    val size = this.view?.layoutManager?.getMeasuredSize(width)

    if (size != null) {
      return YogaMeasureOutput.make(size.first, size.second)
    }

    return YogaMeasureOutput.make(0, 0)
  }

  companion object {
    const val NAME = "EnrichedTextInputView"
  }
}
