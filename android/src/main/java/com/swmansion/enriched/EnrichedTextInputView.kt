package com.swmansion.enriched

import android.content.ClipData
import android.content.ClipboardManager
import android.content.Context
import android.graphics.BlendMode
import android.graphics.BlendModeColorFilter
import android.graphics.Color
import android.graphics.Rect
import android.graphics.text.LineBreaker
import android.os.Build
import android.text.InputType
import android.text.Spannable
import android.util.AttributeSet
import android.util.Log
import android.util.TypedValue
import android.view.Gravity
import android.view.MotionEvent
import android.view.inputmethod.InputMethodManager
import androidx.appcompat.widget.AppCompatEditText
import com.facebook.react.bridge.ReactContext
import com.facebook.react.common.ReactConstants
import com.facebook.react.uimanager.PixelUtil
import com.facebook.react.uimanager.StateWrapper
import com.facebook.react.uimanager.UIManagerHelper
import com.facebook.react.views.text.ReactTypefaceUtils.applyStyles
import com.facebook.react.views.text.ReactTypefaceUtils.parseFontStyle
import com.facebook.react.views.text.ReactTypefaceUtils.parseFontWeight
import com.swmansion.enriched.events.MentionHandler
import com.swmansion.enriched.events.OnInputBlurEvent
import com.swmansion.enriched.events.OnInputFocusEvent
import com.swmansion.enriched.spans.EnrichedImageSpan
import com.swmansion.enriched.spans.EnrichedSpans
import com.swmansion.enriched.styles.InlineStyles
import com.swmansion.enriched.styles.ListStyles
import com.swmansion.enriched.styles.ParagraphStyles
import com.swmansion.enriched.styles.ParametrizedStyles
import com.swmansion.enriched.styles.HtmlStyle
import com.swmansion.enriched.utils.EnrichedParser
import com.swmansion.enriched.utils.EnrichedSelection
import com.swmansion.enriched.utils.EnrichedSpanState
import com.swmansion.enriched.utils.mergeSpannables
import com.swmansion.enriched.watchers.EnrichedSpanWatcher
import com.swmansion.enriched.watchers.EnrichedTextWatcher
import kotlin.math.ceil


class EnrichedTextInputView : AppCompatEditText {
  var stateWrapper: StateWrapper? = null
  val selection: EnrichedSelection? = EnrichedSelection(this)
  val spanState: EnrichedSpanState? = EnrichedSpanState(this)
  val inlineStyles: InlineStyles? = InlineStyles(this)
  val paragraphStyles: ParagraphStyles? = ParagraphStyles(this)
  val listStyles: ListStyles? = ListStyles(this)
  val parametrizedStyles: ParametrizedStyles? = ParametrizedStyles(this)
  var isDuringTransaction: Boolean = false
  var isRemovingMany: Boolean = false
  var scrollEnabled: Boolean = true

  val mentionHandler: MentionHandler? = MentionHandler(this)
  var htmlStyle: HtmlStyle = HtmlStyle(this, null)
  var spanWatcher: EnrichedSpanWatcher? = null
  var layoutManager: EnrichedTextInputViewLayoutManager = EnrichedTextInputViewLayoutManager(this)

  var shouldEmitHtml: Boolean = true
  var experimentalSynchronousEvents: Boolean = false

  var fontSize: Float? = null
  private var autoFocus = false
  private var typefaceDirty = false
  private var didAttachToWindow = false
  private var detectScrollMovement = false
  private var fontFamily: String? = null
  private var fontStyle: Int = ReactConstants.UNSET
  private var fontWeight: Int = ReactConstants.UNSET
  private var defaultValue: CharSequence? = null
  private var defaultValueDirty: Boolean = false

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
    gravity = Gravity.TOP or Gravity.START
    inputType = InputType.TYPE_CLASS_TEXT or InputType.TYPE_TEXT_FLAG_MULTI_LINE

    if (Build.VERSION.SDK_INT >= Build.VERSION_CODES.Q) {
      breakStrategy = LineBreaker.BREAK_STRATEGY_HIGH_QUALITY
    }

    setPadding(0, 0, 0, 0)
    setBackgroundColor(Color.TRANSPARENT)

    addSpanWatcher(EnrichedSpanWatcher(this))
    addTextChangedListener(EnrichedTextWatcher(this))
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

  override fun canScrollVertically(direction: Int): Boolean {
    return scrollEnabled
  }

  override fun canScrollHorizontally(direction: Int): Boolean {
    return scrollEnabled
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
      dispatcher?.dispatchEvent(OnInputFocusEvent(surfaceId, id, experimentalSynchronousEvents))
    } else {
      dispatcher?.dispatchEvent(OnInputBlurEvent(surfaceId, id, experimentalSynchronousEvents))
    }
  }

  override fun onTextContextMenuItem(id: Int): Boolean {
    when (id) {
      android.R.id.copy -> {
        handleCustomCopy()
        return true
      }
      android.R.id.paste -> {
        handleCustomPaste()
        return true
      }
    }
    return super.onTextContextMenuItem(id)
  }

  private fun handleCustomCopy() {
    val start = selectionStart
    val end = selectionEnd
    val spannable = text as Spannable

    if (start < end) {
      val selectedText = spannable.subSequence(start, end) as Spannable
      val selectedHtml = EnrichedParser.toHtml(selectedText)

      val clipboard = context.getSystemService(Context.CLIPBOARD_SERVICE) as ClipboardManager
      val clip = ClipData.newHtmlText(CLIPBOARD_TAG, selectedText, selectedHtml)
      clipboard.setPrimaryClip(clip)
    }
  }

  private fun handleCustomPaste() {
    val clipboard = context.getSystemService(Context.CLIPBOARD_SERVICE) as ClipboardManager
    if (!clipboard.hasPrimaryClip()) return

    val clip = clipboard.primaryClip
    val item = clip?.getItemAt(0)
    val htmlText = item?.htmlText
    val currentText = text as Spannable
    val start = selection?.start ?: 0
    val end = selection?.end ?: 0

    if (htmlText != null) {
      val parsedText = parseText(htmlText)
      if (parsedText is Spannable) {
        val finalText = currentText.mergeSpannables(start, end, parsedText)
        setValue(finalText)
        return
      }
    }

    // Currently, we do not support pasting images
    if (item?.text == null) return
    val finalText = currentText.mergeSpannables(start, end, item.text.toString())
    setValue(finalText)
    parametrizedStyles?.detectAllLinks()
  }

  fun requestFocusProgrammatically() {
    requestFocus()
    inputMethodManager?.showSoftInput(this, 0)
    setSelection(selection?.start ?: text?.length ?: 0)
  }

  private fun parseText(text: CharSequence): CharSequence {
    val isHtml = text.startsWith("<html>") && text.endsWith("</html>")
    if (!isHtml) return text

    try {
      val parsed = EnrichedParser.fromHtml(text.toString(), htmlStyle, null)
      val withoutLastNewLine = parsed.trimEnd('\n')
      return withoutLastNewLine
    } catch (e: Exception) {
      Log.e("EnrichedTextInputView", "Error parsing HTML: ${e.message}")
      return text
    }
  }

  fun setValue(value: CharSequence?) {
    if (value == null) return

    runAsATransaction {
      val newText = parseText(value)
      setText(newText)

      observeAsyncImages()
      // Assign SpanWatcher one more time as our previous spannable has been replaced
      addSpanWatcher(EnrichedSpanWatcher(this))

      // Scroll to the last line of text
      setSelection(text?.length ?: 0)
    }
  }

  /**
   * Finds all async images in the current text and sets up listeners
   * to redraw the text layout when they finish downloading.
   */
  private fun observeAsyncImages() {
    val liveText = text ?: return

    val spans = liveText.getSpans(0, liveText.length, EnrichedImageSpan::class.java)

    for (span in spans) {
      span.observeAsyncDrawableLoaded(liveText)
    }
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

    // This ensured that newly created spans will take the new font size into account
    htmlStyle.invalidateStyles()
    layoutManager.invalidateLayout()
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

  fun setAutoCapitalize(flagName: String?) {
    val flag = when (flagName) {
      "none" -> InputType.TYPE_NULL
      "sentences" -> InputType.TYPE_TEXT_FLAG_CAP_SENTENCES
      "words" -> InputType.TYPE_TEXT_FLAG_CAP_WORDS
      "characters" -> InputType.TYPE_TEXT_FLAG_CAP_CHARACTERS
      else -> InputType.TYPE_NULL
    }

    inputType = (inputType and
      InputType.TYPE_TEXT_FLAG_CAP_CHARACTERS.inv() and
      InputType.TYPE_TEXT_FLAG_CAP_WORDS.inv() and
      InputType.TYPE_TEXT_FLAG_CAP_SENTENCES.inv()
      ) or if (flag == InputType.TYPE_NULL) 0 else flag
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

  fun afterUpdateTransaction() {
    updateTypeface()
    updateDefaultValue()
  }

  fun setDefaultValue(value: CharSequence?) {
    defaultValue = value
    defaultValueDirty = true
  }

  private fun updateDefaultValue() {
    if (!defaultValueDirty) return

    defaultValueDirty = false
    setValue(defaultValue ?: "")
  }

  private fun updateTypeface() {
    if (!typefaceDirty) return
    typefaceDirty = false

    val newTypeface = applyStyles(typeface, fontStyle, fontWeight, fontFamily, context.assets)
    typeface = newTypeface
    paint.typeface = newTypeface

    layoutManager.invalidateLayout()
  }

  private fun toggleStyle(name: String) {
    when (name) {
      EnrichedSpans.BOLD -> inlineStyles?.toggleStyle(EnrichedSpans.BOLD)
      EnrichedSpans.ITALIC -> inlineStyles?.toggleStyle(EnrichedSpans.ITALIC)
      EnrichedSpans.UNDERLINE -> inlineStyles?.toggleStyle(EnrichedSpans.UNDERLINE)
      EnrichedSpans.STRIKETHROUGH -> inlineStyles?.toggleStyle(EnrichedSpans.STRIKETHROUGH)
      EnrichedSpans.INLINE_CODE -> inlineStyles?.toggleStyle(EnrichedSpans.INLINE_CODE)
      EnrichedSpans.H1 -> paragraphStyles?.toggleStyle(EnrichedSpans.H1)
      EnrichedSpans.H2 -> paragraphStyles?.toggleStyle(EnrichedSpans.H2)
      EnrichedSpans.H3 -> paragraphStyles?.toggleStyle(EnrichedSpans.H3)
      EnrichedSpans.H4 -> paragraphStyles?.toggleStyle(EnrichedSpans.H4)
      EnrichedSpans.H5 -> paragraphStyles?.toggleStyle(EnrichedSpans.H5)
      EnrichedSpans.H6 -> paragraphStyles?.toggleStyle(EnrichedSpans.H6)
      EnrichedSpans.CODE_BLOCK -> paragraphStyles?.toggleStyle(EnrichedSpans.CODE_BLOCK)
      EnrichedSpans.BLOCK_QUOTE -> paragraphStyles?.toggleStyle(EnrichedSpans.BLOCK_QUOTE)
      EnrichedSpans.ORDERED_LIST -> listStyles?.toggleStyle(EnrichedSpans.ORDERED_LIST)
      EnrichedSpans.UNORDERED_LIST -> listStyles?.toggleStyle(EnrichedSpans.UNORDERED_LIST)
      else -> Log.w("EnrichedTextInputView", "Unknown style: $name")
    }

    layoutManager.invalidateLayout()
  }

  private fun removeStyle(name: String, start: Int, end: Int): Boolean {
    val removed = when (name) {
      EnrichedSpans.BOLD -> inlineStyles?.removeStyle(EnrichedSpans.BOLD, start, end)
      EnrichedSpans.ITALIC -> inlineStyles?.removeStyle(EnrichedSpans.ITALIC, start, end)
      EnrichedSpans.UNDERLINE -> inlineStyles?.removeStyle(EnrichedSpans.UNDERLINE, start, end)
      EnrichedSpans.STRIKETHROUGH -> inlineStyles?.removeStyle(EnrichedSpans.STRIKETHROUGH, start, end)
      EnrichedSpans.INLINE_CODE -> inlineStyles?.removeStyle(EnrichedSpans.INLINE_CODE, start, end)
      EnrichedSpans.H1 -> paragraphStyles?.removeStyle(EnrichedSpans.H1, start, end)
      EnrichedSpans.H2 -> paragraphStyles?.removeStyle(EnrichedSpans.H2, start, end)
      EnrichedSpans.H3 -> paragraphStyles?.removeStyle(EnrichedSpans.H3, start, end)
      EnrichedSpans.H4 -> paragraphStyles?.removeStyle(EnrichedSpans.H4, start, end)
      EnrichedSpans.H5 -> paragraphStyles?.removeStyle(EnrichedSpans.H5, start, end)
      EnrichedSpans.H6 -> paragraphStyles?.removeStyle(EnrichedSpans.H6, start, end)
      EnrichedSpans.CODE_BLOCK -> paragraphStyles?.removeStyle(EnrichedSpans.CODE_BLOCK, start, end)
      EnrichedSpans.BLOCK_QUOTE -> paragraphStyles?.removeStyle(EnrichedSpans.BLOCK_QUOTE, start, end)
      EnrichedSpans.ORDERED_LIST -> listStyles?.removeStyle(EnrichedSpans.ORDERED_LIST, start, end)
      EnrichedSpans.UNORDERED_LIST -> listStyles?.removeStyle(EnrichedSpans.UNORDERED_LIST, start, end)
      EnrichedSpans.LINK -> parametrizedStyles?.removeStyle(EnrichedSpans.LINK, start, end)
      EnrichedSpans.IMAGE -> parametrizedStyles?.removeStyle(EnrichedSpans.IMAGE, start, end)
      EnrichedSpans.MENTION -> parametrizedStyles?.removeStyle(EnrichedSpans.MENTION, start, end)
      else -> false
    }

    return removed == true
  }

  private fun getTargetRange(name: String): Pair<Int, Int> {
    val result = when (name) {
      EnrichedSpans.BOLD -> inlineStyles?.getStyleRange()
      EnrichedSpans.ITALIC -> inlineStyles?.getStyleRange()
      EnrichedSpans.UNDERLINE -> inlineStyles?.getStyleRange()
      EnrichedSpans.STRIKETHROUGH -> inlineStyles?.getStyleRange()
      EnrichedSpans.INLINE_CODE -> inlineStyles?.getStyleRange()
      EnrichedSpans.H1 -> paragraphStyles?.getStyleRange()
      EnrichedSpans.H2 -> paragraphStyles?.getStyleRange()
      EnrichedSpans.H3 -> paragraphStyles?.getStyleRange()
      EnrichedSpans.H4 -> paragraphStyles?.getStyleRange()
      EnrichedSpans.H5 -> paragraphStyles?.getStyleRange()
      EnrichedSpans.H6 -> paragraphStyles?.getStyleRange()
      EnrichedSpans.CODE_BLOCK -> paragraphStyles?.getStyleRange()
      EnrichedSpans.BLOCK_QUOTE -> paragraphStyles?.getStyleRange()
      EnrichedSpans.ORDERED_LIST -> listStyles?.getStyleRange()
      EnrichedSpans.UNORDERED_LIST -> listStyles?.getStyleRange()
      EnrichedSpans.LINK -> parametrizedStyles?.getStyleRange()
      EnrichedSpans.IMAGE -> parametrizedStyles?.getStyleRange()
      EnrichedSpans.MENTION -> parametrizedStyles?.getStyleRange()
      else -> Pair(0, 0)
    }

    return result ?: Pair(0, 0)
  }

  private fun verifyStyle(name: String): Boolean {
    val mergingConfig = EnrichedSpans.getMergingConfigForStyle(name, htmlStyle) ?: return true
    val conflictingStyles = mergingConfig.conflictingStyles
    val blockingStyles = mergingConfig.blockingStyles
    val isEnabling = spanState?.getStart(name) == null
    if (!isEnabling) return true

    for (style in blockingStyles) {
      if (spanState?.getStart(style) != null) {
        spanState.setStart(name, null)
        return false
      }
    }

    for (style in conflictingStyles) {
      val start = selection?.start ?: 0
      val end = selection?.end ?: 0
      val lengthBefore = text?.length ?: 0

      runAsATransaction {
        val targetRange = getTargetRange(name)
        val removed = removeStyle(style, targetRange.first, targetRange.second)
        if (removed) {
          spanState?.setStart(style, null)
        }
      }

      val lengthAfter = text?.length ?: 0
      val charactersRemoved = lengthBefore - lengthAfter
      val finalEnd = if (charactersRemoved > 0) {
        (end - charactersRemoved).coerceAtLeast(0)
      } else {
        end
      }

      val finalStart = start.coerceAtLeast(0).coerceAtMost(finalEnd)
      selection?.onSelection(finalStart, finalEnd)
    }

    return true
  }

  private fun addSpanWatcher(watcher: EnrichedSpanWatcher) {
    val spannable = text as Spannable
    spannable.setSpan(watcher, 0, spannable.length, Spannable.SPAN_INCLUSIVE_INCLUSIVE)
    spanWatcher = watcher
  }

  fun verifyAndToggleStyle(name: String) {
    val isValid = verifyStyle(name)
    if (!isValid) return

    toggleStyle(name)
  }

  fun addLink(start: Int, end: Int, text: String, url: String) {
    val isValid = verifyStyle(EnrichedSpans.LINK)
    if (!isValid) return

    parametrizedStyles?.setLinkSpan(start, end, text, url)
  }

  fun addImage(src: String, width: Float, height: Float) {
    val isValid = verifyStyle(EnrichedSpans.IMAGE)
    if (!isValid) return

    parametrizedStyles?.setImageSpan(src, width, height)
    layoutManager.invalidateLayout()
  }

  fun startMention(indicator: String) {
    val isValid = verifyStyle(EnrichedSpans.MENTION)
    if (!isValid) return

    parametrizedStyles?.startMention(indicator)
  }

  fun addMention(indicator: String, text: String, attributes: Map<String, String>) {
    val isValid = verifyStyle(EnrichedSpans.MENTION)
    if (!isValid) return

    parametrizedStyles?.setMentionSpan(text, indicator, attributes)
  }

  // Sometimes setting up style triggers many changes in sequence
  // Eg. removing conflicting styles -> changing text -> applying spans
  // In such scenario we want to prevent from handling side effects (eg. onTextChanged)
  fun runAsATransaction(block: () -> Unit) {
    try {
      isDuringTransaction = true
      block()
    } finally {
      isDuringTransaction = false
    }
  }

  override fun onAttachedToWindow() {
    super.onAttachedToWindow()

    if (autoFocus && !didAttachToWindow) {
      requestFocusProgrammatically()
    }

    didAttachToWindow = true
  }

  companion object {
    const val CLIPBOARD_TAG = "react-native-enriched-clipboard"
  }
}
