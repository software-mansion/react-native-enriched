package com.swmansion.reactnativerichtexteditor

import android.content.Context
import android.graphics.BlendMode
import android.graphics.BlendModeColorFilter
import android.graphics.Color
import android.graphics.Rect
import android.os.Build
import android.text.Spannable
import android.text.StaticLayout
import android.text.method.LinkMovementMethod
import android.util.AttributeSet
import android.util.Log
import android.util.TypedValue
import android.view.MotionEvent
import android.view.inputmethod.InputMethodManager
import androidx.appcompat.widget.AppCompatEditText
import com.facebook.react.bridge.Arguments
import com.facebook.react.bridge.ReactContext
import com.facebook.react.common.ReactConstants
import com.facebook.react.uimanager.PixelUtil
import com.facebook.react.uimanager.StateWrapper
import com.facebook.react.uimanager.UIManagerHelper
import com.facebook.react.views.text.ReactTypefaceUtils.applyStyles
import com.facebook.react.views.text.ReactTypefaceUtils.parseFontStyle
import com.facebook.react.views.text.ReactTypefaceUtils.parseFontWeight
import com.swmansion.reactnativerichtexteditor.events.LinkHandler
import com.swmansion.reactnativerichtexteditor.events.MentionHandler
import com.swmansion.reactnativerichtexteditor.events.OnBlurEvent
import com.swmansion.reactnativerichtexteditor.events.OnFocusEvent
import com.swmansion.reactnativerichtexteditor.spans.EditorSpans
import com.swmansion.reactnativerichtexteditor.styles.InlineStyles
import com.swmansion.reactnativerichtexteditor.styles.ListStyles
import com.swmansion.reactnativerichtexteditor.styles.ParagraphStyles
import com.swmansion.reactnativerichtexteditor.styles.ParametrizedStyles
import com.swmansion.reactnativerichtexteditor.utils.EditorParser
import com.swmansion.reactnativerichtexteditor.utils.EditorSelection
import com.swmansion.reactnativerichtexteditor.utils.EditorSpanState
import com.swmansion.reactnativerichtexteditor.watchers.EditorSpanWatcher
import com.swmansion.reactnativerichtexteditor.watchers.EditorTextWatcher
import kotlin.math.ceil


class ReactNativeRichTextEditorView : AppCompatEditText {
  private var stateWrapper: StateWrapper? = null
  val selection: EditorSelection? = EditorSelection(this)
  val spanState: EditorSpanState? = EditorSpanState(this)
  val inlineStyles: InlineStyles? = InlineStyles(this)
  val paragraphStyles: ParagraphStyles? = ParagraphStyles(this)
  val listStyles: ListStyles? = ListStyles(this)
  val parametrizedStyles: ParametrizedStyles? = ParametrizedStyles(this)
  var isSettingValue: Boolean = false

  var linkHandler: LinkHandler? = LinkHandler(this)
  val mentionHandler: MentionHandler? = MentionHandler(this)

  private var autoFocus = false
  private var typefaceDirty = false
  private var didAttachToWindow = false
  private var detectScrollMovement = false
  private var fontSize: Float? = null
  private var fontFamily: String? = null
  private var fontStyle: Int = ReactConstants.UNSET
  private var fontWeight: Int = ReactConstants.UNSET
  private var forceHeightRecalculationCounter: Int = 0

  private var inputMethodManager: InputMethodManager? = null

  constructor(context: Context) : super(context) {
    prepareComponent()
  }

  constructor(context: Context, attrs: AttributeSet) : super(context, attrs) {
    prepareComponent()
  }

  constructor(context: Context, attrs: AttributeSet, defStyleAttr: Int) : super(
    context,
    attrs,
    defStyleAttr
  ) {
    prepareComponent()
  }

  init {
      inputMethodManager = context.getSystemService(Context.INPUT_METHOD_SERVICE) as InputMethodManager
  }

  private fun prepareComponent() {
    isSingleLine = false
    isHorizontalScrollBarEnabled = false
    isVerticalScrollBarEnabled = true
    gravity = android.view.Gravity.TOP or android.view.Gravity.START
    inputType = android.text.InputType.TYPE_CLASS_TEXT or android.text.InputType.TYPE_TEXT_FLAG_MULTI_LINE

    // required to make ClickableSpans really clickable
    movementMethod = LinkMovementMethod.getInstance()

    setPadding(0, 0, 0, 0)
    setBackgroundColor(Color.TRANSPARENT)

    addSpanWatcher(EditorSpanWatcher(this))
    addTextChangedListener(EditorTextWatcher(this))
  }

  // https://github.com/facebook/react-native/blob/36df97f500aa0aa8031098caf7526db358b6ddc1/packages/react-native/ReactAndroid/src/main/java/com/facebook/react/views/textinput/ReactEditText.kt#L295C1-L296C1
  override fun onTouchEvent(ev: MotionEvent): Boolean {
    when (ev.action) {
      MotionEvent.ACTION_DOWN -> {
        detectScrollMovement = true
        // Disallow parent views to intercept touch events, until we can detect if we should be
        // capturing these touches or not.
        this.parent.requestDisallowInterceptTouchEvent(true)
      }

      MotionEvent.ACTION_MOVE ->
        if (detectScrollMovement) {
          if (!canScrollVertically(-1) &&
            !canScrollVertically(1) &&
            !canScrollHorizontally(-1) &&
            !canScrollHorizontally(1)) {
            // We cannot scroll, let parent views take care of these touches.
            this.parent.requestDisallowInterceptTouchEvent(false)
          }
          detectScrollMovement = false
        }
    }

    return super.onTouchEvent(ev)
  }

  override fun onSelectionChanged(selStart: Int, selEnd: Int) {
    super.onSelectionChanged(selStart, selEnd)
    selection?.onSelection(selStart, selEnd)
  }

  override fun clearFocus() {
    super.clearFocus()
    inputMethodManager?.hideSoftInputFromWindow(windowToken, 0)
  }

  override fun onFocusChanged(focused: Boolean, direction: Int, previouslyFocusedRect: Rect?) {
    super.onFocusChanged(focused, direction, previouslyFocusedRect)
    val context = context as ReactContext
    val surfaceId = UIManagerHelper.getSurfaceId(context)
    val dispatcher = UIManagerHelper.getEventDispatcherForReactTag(context, id)

    if (focused) {
      dispatcher?.dispatchEvent(OnFocusEvent(surfaceId, id))
    } else {
      dispatcher?.dispatchEvent(OnBlurEvent(surfaceId, id))
    }
  }

  fun setStateWrapper(sw: StateWrapper?) {
    stateWrapper = sw
  }

  fun requestFocusProgrammatically() {
    requestFocus()
    inputMethodManager?.showSoftInput(this, 0)
    setSelection(selection?.start ?: text?.length ?: 0)
  }

  fun setValue(value: String?) {
    if (value == null) return
    isSettingValue = true

    val isHtmlTagRecognized = value.startsWith("<html>") && value.endsWith("</html>")
    val isPTagRecognized = value.startsWith("<p>") && value.endsWith("</p>")
    val isHtml = isHtmlTagRecognized || isPTagRecognized
    if (isHtml) {
      val parsed = EditorParser.fromHtml(value, EditorParser.FROM_HTML_MODE_COMPACT, null, null, linkHandler, mentionHandler)
      setText(parsed)
    } else {
      setText(value)
    }

    // Assign SpanWatcher one more time as our previous spannable has been replaced
    addSpanWatcher(EditorSpanWatcher(this))

    // Scroll to the last line of text
    setSelection(text?.length ?: 0)

    isSettingValue = false
  }

  fun setAutoFocus(autoFocus: Boolean) {
    this.autoFocus = autoFocus
  }

  fun setPlaceholder(placeholder: String?) {
    if (placeholder == null) return

    hint = placeholder
  }

  fun setPlaceholderTextColor(colorInt: Int?) {
    if (colorInt == null) return

    setHintTextColor(colorInt)
  }

  fun setSelectionColor(colorInt: Int?) {
    if (colorInt == null) return

    highlightColor = colorInt
  }

  fun setCursorColor(colorInt: Int?) {
    if (Build.VERSION.SDK_INT >= Build.VERSION_CODES.Q) {
      val cursorDrawable = textCursorDrawable
      if (cursorDrawable == null) return

      if (colorInt != null) {
        cursorDrawable.colorFilter = BlendModeColorFilter(colorInt, BlendMode.SRC_IN)
      } else {
        cursorDrawable.clearColorFilter()
      }

      textCursorDrawable = cursorDrawable
    }
  }

  fun setColor(colorInt: Int?) {
    if (colorInt == null) {
      setTextColor(Color.BLACK)
      return
    }

    setTextColor(colorInt)
  }

  fun setFontSize(size: Float) {
    if (size == 0f) return

    val sizeInt = ceil(PixelUtil.toPixelFromSP(size))
    fontSize = sizeInt
    setTextSize(TypedValue.COMPLEX_UNIT_PX, sizeInt)

    updateYogaState()
  }

  fun setFontFamily(family: String?) {
    if (family != fontFamily) {
      fontFamily = family
      typefaceDirty = true
    }
  }

  fun setFontWeight(weight: String?) {
    val fontWeight = parseFontWeight(weight)

    if (fontWeight != fontStyle) {
      this.fontWeight = fontWeight
      typefaceDirty = true
    }
  }

  fun setFontStyle(style: String?) {
    val fontStyle = parseFontStyle(style)

    if (fontStyle != this.fontStyle) {
      this.fontStyle = fontStyle
      typefaceDirty = true
    }
  }

  // https://github.com/facebook/react-native/blob/36df97f500aa0aa8031098caf7526db358b6ddc1/packages/react-native/ReactAndroid/src/main/java/com/facebook/react/views/textinput/ReactEditText.kt#L283C2-L284C1
  // After the text changes inside an EditText, TextView checks if a layout() has been requested.
  // If it has, it will not scroll the text to the end of the new text inserted, but wait for the
  // next layout() to be called. However, we do not perform a layout() after a requestLayout(), so
  // we need to override isLayoutRequested to force EditText to scroll to the end of the new text
  // immediately.
  override fun isLayoutRequested(): Boolean {
    return false
  }

  fun measureSize(maxWidth: Float): Pair<Float, Float> {
    val paint = this.paint
    val spannable = text as Spannable
    val spannableLength = spannable.length

    val staticLayout = StaticLayout.Builder
      .obtain(spannable, 0, spannableLength, paint, maxWidth.toInt())
      .setIncludePad(true)
      .setLineSpacing(0f, 1f)
      .build()

    val heightInSP = PixelUtil.toDIPFromPixel(staticLayout.height.toFloat())
    val widthInSP = PixelUtil.toDIPFromPixel(maxWidth)

    return Pair(widthInSP, heightInSP)
  }

  fun updateTypeface() {
    if (!typefaceDirty) return
    typefaceDirty = false

    val newTypeface = applyStyles(typeface, fontStyle, fontWeight, fontFamily, context.assets)
    typeface = newTypeface
    paint.typeface = newTypeface

    updateYogaState()
  }

  private fun toggleStyle(name: String) {
    when (name) {
      EditorSpans.BOLD -> inlineStyles?.toggleStyle(EditorSpans.BOLD)
      EditorSpans.ITALIC -> inlineStyles?.toggleStyle(EditorSpans.ITALIC)
      EditorSpans.UNDERLINE -> inlineStyles?.toggleStyle(EditorSpans.UNDERLINE)
      EditorSpans.STRIKETHROUGH -> inlineStyles?.toggleStyle(EditorSpans.STRIKETHROUGH)
      EditorSpans.INLINE_CODE -> inlineStyles?.toggleStyle(EditorSpans.INLINE_CODE)
      EditorSpans.H1 -> paragraphStyles?.toggleStyle(EditorSpans.H1)
      EditorSpans.H2 -> paragraphStyles?.toggleStyle(EditorSpans.H2)
      EditorSpans.H3 -> paragraphStyles?.toggleStyle(EditorSpans.H3)
      EditorSpans.CODE_BLOCK -> paragraphStyles?.toggleStyle(EditorSpans.CODE_BLOCK)
      EditorSpans.BLOCK_QUOTE -> paragraphStyles?.toggleStyle(EditorSpans.BLOCK_QUOTE)
      EditorSpans.ORDERED_LIST -> listStyles?.toggleStyle(EditorSpans.ORDERED_LIST)
      EditorSpans.UNORDERED_LIST -> listStyles?.toggleStyle(EditorSpans.UNORDERED_LIST)
      else -> Log.w("ReactNativeRichTextEditorView", "Unknown style: $name")
    }
  }

  private fun verifyStyle(name: String): Boolean {
    val mergingConfig = EditorSpans.mergingConfig[name] ?: return true
    val conflictingStyles = mergingConfig.conflictingStyles
    val blockingStyles = mergingConfig.blockingStyles

    for (style in blockingStyles) {
      if (spanState?.getStart(style) != null) {
        spanState.setStart(name, null)
        return false
      }
    }

    for (style in conflictingStyles) {
      if (spanState?.getStart(style) != null) {
        toggleStyle(style)
      }
    }

    return true
  }

  private fun addSpanWatcher(watcher: EditorSpanWatcher) {
    val spannable = text as Spannable
    spannable.setSpan(watcher, 0, spannable.length, Spannable.SPAN_INCLUSIVE_INCLUSIVE)
  }

  fun verifyAndToggleStyle(name: String) {
    val isValid = verifyStyle(name)
    if (!isValid) return

    toggleStyle(name)
  }

  fun addLink(start: Int, end: Int, text: String, url: String) {
    val isValid = verifyStyle(EditorSpans.LINK)
    if (!isValid) return

    parametrizedStyles?.setLinkSpan(start, end, text, url)
  }

  fun addImage(src: String) {
    val isValid = verifyStyle(EditorSpans.IMAGE)
    if (!isValid) return

    parametrizedStyles?.setImageSpan(src)
  }

  fun startMention(indicator: String) {
    val isValid = verifyStyle(EditorSpans.MENTION)
    if (!isValid) return

    parametrizedStyles?.startMention(indicator)
  }

  fun addMention(indicator: String, text: String, value: String) {
    val isValid = verifyStyle(EditorSpans.MENTION)
    if (!isValid) return

    parametrizedStyles?.setMentionSpan(indicator, text, value)
  }

  // Update shadow node's state in order to recalculate layout
  fun updateYogaState() {
    val counter = forceHeightRecalculationCounter
    forceHeightRecalculationCounter++
    val state = Arguments.createMap()

    state.putInt("forceHeightRecalculationCounter", counter)
    stateWrapper?.updateState(state)
  }

  override fun onAttachedToWindow() {
    super.onAttachedToWindow()

    if (autoFocus && !didAttachToWindow) {
      requestFocusProgrammatically()
    }

    didAttachToWindow = true
  }

  override fun onDetachedFromWindow() {
    forceHeightRecalculationCounter = 0

    super.onDetachedFromWindow()
  }
}
