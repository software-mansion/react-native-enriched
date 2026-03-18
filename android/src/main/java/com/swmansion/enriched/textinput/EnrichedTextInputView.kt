package com.swmansion.enriched.textinput

import android.content.ClipData
import android.content.ClipboardManager
import android.content.Context
import android.graphics.BlendMode
import android.graphics.BlendModeColorFilter
import android.graphics.Color
import android.graphics.Rect
import android.graphics.text.LineBreaker
import android.os.Build
import android.text.Editable
import android.text.InputType
import android.text.Layout
import android.text.Spannable
import android.text.SpannableStringBuilder
import android.text.Spanned
import android.text.style.AlignmentSpan
import android.util.AttributeSet
import android.util.Log
import android.util.Patterns
import android.util.TypedValue
import android.view.ActionMode
import android.view.Gravity
import android.view.Menu
import android.view.MenuItem
import android.view.MotionEvent
import android.view.inputmethod.EditorInfo
import android.view.inputmethod.InputConnection
import android.view.inputmethod.InputMethodManager
import androidx.appcompat.widget.AppCompatEditText
import androidx.core.view.ViewCompat
import com.facebook.react.bridge.ReactContext
import com.facebook.react.bridge.ReadableArray
import com.facebook.react.bridge.ReadableMap
import com.facebook.react.common.ReactConstants
import com.facebook.react.uimanager.PixelUtil
import com.facebook.react.uimanager.StateWrapper
import com.facebook.react.uimanager.UIManagerHelper
import com.facebook.react.views.text.ReactTypefaceUtils.applyStyles
import com.facebook.react.views.text.ReactTypefaceUtils.parseFontStyle
import com.facebook.react.views.text.ReactTypefaceUtils.parseFontWeight
import com.swmansion.enriched.common.EnrichedConstants
import com.swmansion.enriched.common.GumboNormalizer
import com.swmansion.enriched.common.parser.EnrichedParser
import com.swmansion.enriched.textinput.events.MentionHandler
import com.swmansion.enriched.textinput.events.OnContextMenuItemPressEvent
import com.swmansion.enriched.textinput.events.OnInputBlurEvent
import com.swmansion.enriched.textinput.events.OnInputFocusEvent
import com.swmansion.enriched.textinput.events.OnRequestHtmlResultEvent
import com.swmansion.enriched.textinput.spans.EnrichedInputH1Span
import com.swmansion.enriched.textinput.spans.EnrichedInputH2Span
import com.swmansion.enriched.textinput.spans.EnrichedInputH3Span
import com.swmansion.enriched.textinput.spans.EnrichedInputH4Span
import com.swmansion.enriched.textinput.spans.EnrichedInputH5Span
import com.swmansion.enriched.textinput.spans.EnrichedInputH6Span
import com.swmansion.enriched.textinput.spans.EnrichedInputCheckboxListSpan
import com.swmansion.enriched.textinput.spans.EnrichedInputImageSpan
import com.swmansion.enriched.textinput.spans.EnrichedInputLinkSpan
import com.swmansion.enriched.textinput.spans.EnrichedLineHeightSpan
import com.swmansion.enriched.textinput.spans.EnrichedInputOrderedListSpan
import com.swmansion.enriched.textinput.spans.EnrichedInputUnorderedListSpan
import com.swmansion.enriched.textinput.spans.EnrichedAlignmentPlaceholderSpan
import com.swmansion.enriched.textinput.spans.EnrichedSpans
import com.swmansion.enriched.textinput.spans.interfaces.EnrichedInputSpan
import com.swmansion.enriched.textinput.styles.HtmlStyle
import com.swmansion.enriched.textinput.styles.InlineStyles
import com.swmansion.enriched.textinput.styles.ListStyles
import com.swmansion.enriched.textinput.styles.ParagraphStyles
import com.swmansion.enriched.textinput.styles.ParametrizedStyles
import com.swmansion.enriched.textinput.utils.EnrichedEditableFactory
import com.swmansion.enriched.textinput.utils.EnrichedSelection
import com.swmansion.enriched.textinput.utils.EnrichedSpanState
import com.swmansion.enriched.textinput.utils.RichContentReceiver
import com.swmansion.enriched.textinput.utils.getParagraphBounds
import com.swmansion.enriched.textinput.utils.getParagraphRangesInRange
import com.swmansion.enriched.textinput.utils.getSafeSpanBoundaries
import com.swmansion.enriched.textinput.utils.mergeSpannables
import com.swmansion.enriched.textinput.utils.setCheckboxClickListener
import com.swmansion.enriched.textinput.utils.zwsCountBefore
import com.swmansion.enriched.textinput.watchers.EnrichedSpanWatcher
import com.swmansion.enriched.textinput.watchers.EnrichedTextWatcher
import java.util.regex.Pattern
import java.util.regex.PatternSyntaxException
import kotlin.math.ceil

class EnrichedTextInputView : AppCompatEditText {
  var stateWrapper: StateWrapper? = null
  val selection: EnrichedSelection? = EnrichedSelection(this)
  val spanState: EnrichedSpanState? = EnrichedSpanState(this)
  val inlineStyles: InlineStyles? = InlineStyles(this)
  val paragraphStyles: ParagraphStyles? = ParagraphStyles(this)
  val listStyles: ListStyles? = ListStyles(this)
  val parametrizedStyles: ParametrizedStyles? = ParametrizedStyles(this)
  private var transactionDepth: Int = 0
  val isDuringTransaction: Boolean
    get() = transactionDepth > 0
  var isRemovingMany: Boolean = false
  var scrollEnabled: Boolean = true

  val mentionHandler: MentionHandler? = MentionHandler(this)
  var htmlStyle: HtmlStyle = HtmlStyle(this, null)
    set(value) {
      if (field != value) {
        val prev = field
        field = value
        reApplyHtmlStyleForSpans(prev, value)
      }
    }

  var linkRegex: Pattern? = Patterns.WEB_URL
  var spanWatcher: EnrichedSpanWatcher? = null
  var layoutManager: EnrichedTextInputViewLayoutManager = EnrichedTextInputViewLayoutManager(this)

  var shouldEmitHtml: Boolean = false
  var shouldEmitOnChangeText: Boolean = false
  var experimentalSynchronousEvents: Boolean = false
  var useHtmlNormalizer: Boolean = false

  var fontSize: Float? = null
  private var lineHeight: Float? = null
  private var autoFocus = false
  private var typefaceDirty = false
  private var didAttachToWindow = false
  private var detectScrollMovement = false
  private var fontFamily: String? = null
  private var fontStyle: Int = ReactConstants.UNSET
  private var fontWeight: Int = ReactConstants.UNSET
  private var defaultValue: CharSequence? = null
  private var defaultValueDirty: Boolean = false
  private var typingAlignment: Layout.Alignment = Layout.Alignment.ALIGN_NORMAL

  private var inputMethodManager: InputMethodManager? = null
  private val spannableFactory = EnrichedTextInputSpannableFactory()
  private var contextMenuItems: List<Pair<Int, String>> = emptyList()

  constructor(context: Context) : super(context) {
    prepareComponent()
  }

  constructor(context: Context, attrs: AttributeSet) : super(context, attrs) {
    prepareComponent()
  }

  constructor(context: Context, attrs: AttributeSet, defStyleAttr: Int) : super(
    context,
    attrs,
    defStyleAttr,
  ) {
    prepareComponent()
  }

  override fun onCreateInputConnection(outAttrs: EditorInfo): InputConnection? {
    var inputConnection = super.onCreateInputConnection(outAttrs)
    if (inputConnection != null) {
      inputConnection =
        EnrichedTextInputConnectionWrapper(
          inputConnection,
          context as ReactContext,
          this,
          experimentalSynchronousEvents,
        )
    }

    return inputConnection
  }

  init {
    inputMethodManager = context.getSystemService(Context.INPUT_METHOD_SERVICE) as InputMethodManager
    ViewCompat.setOnReceiveContentListener(
      this,
      RichContentReceiver.MIME_TYPES,
      RichContentReceiver(this, context as ReactContext),
    )
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

    // Ensure that every time new editable is created, it has EnrichedSpanWatcher attached
    val spanWatcher = EnrichedSpanWatcher(this)
    this.spanWatcher = spanWatcher

    setEditableFactory(EnrichedEditableFactory(spanWatcher))
    addTextChangedListener(EnrichedTextWatcher(this))

    // Handle checkbox list item clicks
    this.setCheckboxClickListener()
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

      MotionEvent.ACTION_MOVE -> {
        if (detectScrollMovement) {
          if (!canScrollVertically(-1) &&
            !canScrollVertically(1) &&
            !canScrollHorizontally(-1) &&
            !canScrollHorizontally(1)
          ) {
            // We cannot scroll, let parent views take care of these touches.
            this.parent.requestDisallowInterceptTouchEvent(false)
          }
          detectScrollMovement = false
        }
      }
    }

    return super.onTouchEvent(ev)
  }

  override fun canScrollVertically(direction: Int): Boolean = scrollEnabled

  override fun canScrollHorizontally(direction: Int): Boolean = scrollEnabled

  override fun bringPointIntoView(offset: Int): Boolean {
    val result = super.bringPointIntoView(offset)
    if (scrollX != 0) {
      scrollTo(0, scrollY)
    }
    return result
  }

  override fun onSelectionChanged(
    selStart: Int,
    selEnd: Int,
  ) {
    super.onSelectionChanged(selStart, selEnd)
    selection?.onSelection(selStart, selEnd)
  }

  override fun clearFocus() {
    super.clearFocus()
    inputMethodManager?.hideSoftInputFromWindow(windowToken, 0)
  }

  override fun onFocusChanged(
    focused: Boolean,
    direction: Int,
    previouslyFocusedRect: Rect?,
  ) {
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

  fun handleTextPaste(item: ClipData.Item) {
    val htmlText = item.htmlText
    val currentText = text as Spannable
    val start = selectionStart.coerceAtLeast(0)
    val end = selectionEnd.coerceAtLeast(0)

    if (htmlText != null) {
      val parsedText = parseText(htmlText)
      if (parsedText is Spannable) {
        val finalText = currentText.mergeSpannables(start, end, parsedText)
        setValue(finalText, false)
        return
      }
    }

    if (item.text == null) return
    val lengthBefore = currentText.length
    val finalText = currentText.mergeSpannables(start, end, item.text.toString())
    setValue(finalText)

    // Detect links in the newly pasted range
    val finalEndIndex = start + finalText.length - lengthBefore
    parametrizedStyles?.detectLinksInRange(finalText, start, finalEndIndex)
  }

  fun requestFocusProgrammatically() {
    requestFocus()
    inputMethodManager?.showSoftInput(this, 0)
    setSelection(selection?.start ?: text?.length ?: 0)
  }

  private fun normalizeHtmlIfNeeded(text: CharSequence): CharSequence {
    if (!useHtmlNormalizer) return text
    val normalized = GumboNormalizer.normalizeHtml(text.toString()) ?: return text

    return try {
      val parsed = EnrichedParser.fromHtml(normalized, htmlStyle, spannableFactory)
      parsed.trimEnd('\n')
    } catch (e: Exception) {
      Log.e(TAG, "Error parsing normalized HTML: ${e.message}")
      text
    }
  }

  private fun parseText(text: CharSequence): CharSequence {
    val isInternalHtml = text.startsWith("<html>") && text.endsWith("</html>")

    if (isInternalHtml) {
      try {
        val parsed = EnrichedParser.fromHtml(text.toString(), htmlStyle, spannableFactory)
        return parsed.trimEnd('\n')
      } catch (e: Exception) {
        Log.e(TAG, "Error parsing HTML: ${e.message}")
        return normalizeHtmlIfNeeded(text)
      }
    }

    return normalizeHtmlIfNeeded(text)
  }

  fun setValue(
    value: CharSequence?,
    shouldParseHtml: Boolean = true,
  ) {
    if (value == null) return

    runAsATransaction {
      val newText = if (shouldParseHtml) parseText(value) else value
      setText(newText)
      applyLineSpacing()

      observeAsyncImages()

      // Scroll to the last line of text
      setSelection(text?.length ?: 0)
    }
    layoutManager.invalidateLayout()
  }

  fun setCustomSelection(
    visibleStart: Int,
    visibleEnd: Int,
  ) {
    val actualStart = getActualIndex(visibleStart)
    val actualEnd = getActualIndex(visibleEnd)

    setSelection(actualStart, actualEnd)
  }

  // Helper: Walks through the string skipping ZWSPs to find the Nth visible character
  private fun getActualIndex(visibleIndex: Int): Int {
    val currentText = text as Spannable
    var currentVisibleCount = 0
    var actualIndex = 0

    while (actualIndex < currentText.length) {
      if (currentVisibleCount == visibleIndex) {
        return actualIndex
      }

      // If the current char is not a hidden space, it counts towards our visible index
      if (currentText[actualIndex] != EnrichedConstants.ZWS) {
        currentVisibleCount++
      }
      actualIndex++
    }

    return actualIndex
  }

  /**
   * Finds all async images in the current text and sets up listeners
   * to redraw the text layout when they finish downloading.
   */
  private fun observeAsyncImages() {
    val liveText = text ?: return

    val spans = liveText.getSpans(0, liveText.length, EnrichedInputImageSpan::class.java)

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
      val cursorDrawable = textCursorDrawable ?: return

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
    forceScrollToSelection()
  }

  fun setLineHeight(height: Float) {
    lineHeight = if (height == 0f) null else height
    applyLineSpacing()
    layoutManager.invalidateLayout()
    forceScrollToSelection()
  }

  private fun applyLineSpacing() {
    val spannable = text as? Spannable ?: return
    spannable
      .getSpans(0, spannable.length, EnrichedLineHeightSpan::class.java)
      .forEach { spannable.removeSpan(it) }

    val lh = lineHeight ?: return
    spannable.setSpan(
      EnrichedLineHeightSpan(lh),
      0,
      spannable.length,
      Spannable.SPAN_INCLUSIVE_INCLUSIVE,
    )
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
    val flag =
      when (flagName) {
        "none" -> InputType.TYPE_NULL
        "sentences" -> InputType.TYPE_TEXT_FLAG_CAP_SENTENCES
        "words" -> InputType.TYPE_TEXT_FLAG_CAP_WORDS
        "characters" -> InputType.TYPE_TEXT_FLAG_CAP_CHARACTERS
        else -> InputType.TYPE_NULL
      }

    inputType = (
      inputType and
        InputType.TYPE_TEXT_FLAG_CAP_CHARACTERS.inv() and
        InputType.TYPE_TEXT_FLAG_CAP_WORDS.inv() and
        InputType.TYPE_TEXT_FLAG_CAP_SENTENCES.inv()
    ) or if (flag == InputType.TYPE_NULL) 0 else flag
  }

  fun setLinkRegex(config: ReadableMap?) {
    val patternStr = config?.getString("pattern")
    if (patternStr == null) {
      linkRegex = Patterns.WEB_URL
      return
    }

    if (config.getBoolean("isDefault")) {
      linkRegex = Patterns.WEB_URL
      return
    }

    if (config.getBoolean("isDisabled")) {
      linkRegex = null
      return
    }

    var flags = 0
    if (config.getBoolean("caseInsensitive")) flags = flags or Pattern.CASE_INSENSITIVE
    if (config.getBoolean("dotAll")) flags = flags or Pattern.DOTALL

    try {
      linkRegex = Pattern.compile("(?s).*?($patternStr).*", flags)
    } catch (_: PatternSyntaxException) {
      Log.w(TAG, "Invalid link regex pattern: $patternStr")
      linkRegex = Patterns.WEB_URL
    }
  }

  fun setContextMenuItems(items: ReadableArray?) {
    if (items == null) {
      contextMenuItems = emptyList()
      return
    }

    val result = mutableListOf<Pair<Int, String>>()
    for (i in 0 until items.size()) {
      val item = items.getMap(i) ?: continue
      val text = item.getString("text") ?: continue
      result.add(Pair(i, text))
    }

    contextMenuItems = result
  }

  override fun startActionMode(
    callback: ActionMode.Callback?,
    type: Int,
  ): ActionMode? {
    if (contextMenuItems.isEmpty()) {
      return super.startActionMode(callback, type)
    }

    val wrappedCallback =
      object : ActionMode.Callback2() {
        override fun onCreateActionMode(
          mode: ActionMode,
          menu: Menu,
        ): Boolean {
          val result = callback?.onCreateActionMode(mode, menu) ?: false
          for ((index, text) in contextMenuItems) {
            menu.add(Menu.NONE, CONTEXT_MENU_ITEM_ID + index, Menu.NONE, text)
          }

          return result
        }

        override fun onPrepareActionMode(
          mode: ActionMode,
          menu: Menu,
        ) = callback?.onPrepareActionMode(mode, menu) ?: false

        override fun onActionItemClicked(
          mode: ActionMode,
          menuItem: MenuItem,
        ): Boolean {
          val itemId = menuItem.itemId
          if (itemId < CONTEXT_MENU_ITEM_ID) {
            return callback?.onActionItemClicked(mode, menuItem) ?: false
          }

          val selStart = selection?.start ?: 0
          val selEnd = selection?.end ?: 0
          val itemText = contextMenuItems.getOrNull(itemId - CONTEXT_MENU_ITEM_ID)?.second ?: return false
          emitContextMenuItemPressEvent(itemText)
          mode.finish()
          post {
            // Ensures selection is not lost after the action mode is finished
            if (selStart in 0..selEnd) {
              setSelection(selStart, selEnd)
            }
          }
          return true
        }

        override fun onDestroyActionMode(mode: ActionMode) {
          callback?.onDestroyActionMode(mode)
        }
      }

    return super.startActionMode(wrappedCallback, type)
  }

  private fun emitContextMenuItemPressEvent(itemText: String) {
    val start = selection?.start ?: return
    val end = selection.end
    val styleState = spanState?.getStyleStatePayload() ?: return
    val currentText = text ?: return
    val selectedText = currentText.subSequence(start, end).toString().replace(EnrichedConstants.ZWS_STRING, "")

    val visibleStart = start - currentText.zwsCountBefore(start)
    val visibleEnd = end - currentText.zwsCountBefore(end)

    val reactContext = context as ReactContext
    val surfaceId = UIManagerHelper.getSurfaceId(reactContext)
    val dispatcher = UIManagerHelper.getEventDispatcherForReactTag(reactContext, id)
    dispatcher?.dispatchEvent(
      OnContextMenuItemPressEvent(
        surfaceId,
        id,
        itemText,
        selectedText,
        visibleStart,
        visibleEnd,
        styleState,
        experimentalSynchronousEvents,
      ),
    )
  }

  fun setTextAlignment(alignment: String) {
    val layoutAlignment =
      when (alignment.lowercase()) {
        "left", "default" -> Layout.Alignment.ALIGN_NORMAL
        "center" -> Layout.Alignment.ALIGN_CENTER
        "right" -> Layout.Alignment.ALIGN_OPPOSITE
        "justify" -> Layout.Alignment.ALIGN_NORMAL
        else -> Layout.Alignment.ALIGN_NORMAL
      }

    val spannable = text as? SpannableStringBuilder ?: return
    typingAlignment = layoutAlignment

    if (spannable.isEmpty()) {
      if (layoutAlignment != Layout.Alignment.ALIGN_NORMAL) {
        runAsATransaction {
          spannable.insert(0, EnrichedConstants.ZWS_STRING)
          spannable.setSpan(
            EnrichedAlignmentPlaceholderSpan(),
            0,
            1,
            Spanned.SPAN_EXCLUSIVE_EXCLUSIVE,
          )
          spannable.setSpan(
            AlignmentSpan.Standard(layoutAlignment),
            0,
            1,
            Spanned.SPAN_EXCLUSIVE_EXCLUSIVE,
          )
        }
        setSelection(1)
        layoutManager.invalidateLayout()
        requestLayout()
        invalidate()
      }
      return
    }

    val (initialStart, initialEnd) =
      selection?.getParagraphSelection()
        ?: Pair(selectionStart.coerceIn(0, spannable.length), selectionEnd.coerceIn(0, spannable.length))
    val (start, end) = spannable.getSafeSpanBoundaries(initialStart, initialEnd)
    val targetRange = expandRangeToContiguousList(spannable, start, end)
    val paragraphRanges = spannable.getParagraphRangesInRange(targetRange.first, targetRange.second)

    val cursorStart = selectionStart
    val cursorEnd = selectionEnd
    runAsATransaction {
      for ((paragraphStart, paragraphEnd) in paragraphRanges) {
        removeAlignmentSpans(spannable, paragraphStart, paragraphEnd)
        if (layoutAlignment != Layout.Alignment.ALIGN_NORMAL && paragraphStart < paragraphEnd) {
          spannable.setSpan(
            AlignmentSpan.Standard(layoutAlignment),
            paragraphStart,
            paragraphEnd,
            Spanned.SPAN_EXCLUSIVE_EXCLUSIVE,
          )
        }
      }
    }

    setSelection(cursorStart.coerceIn(0, spannable.length), cursorEnd.coerceIn(0, spannable.length))
    layoutManager.invalidateLayout()
    requestLayout()
    invalidate()
    spanState?.emitStateChangeEvent()
  }

  fun getCurrentAlignment(): String {
    val spannable = text as? Spannable ?: return "left"
    val (start, end) = selection?.getParagraphSelection() ?: Pair(selectionStart, selectionEnd)
    val alignment = getParagraphAlignment(spannable, start, end)
    return when (alignment) {
      Layout.Alignment.ALIGN_NORMAL -> "left"
      Layout.Alignment.ALIGN_CENTER -> "center"
      Layout.Alignment.ALIGN_OPPOSITE -> "right"
    }
  }

  fun applyTypingAlignmentIfNeeded(
    editable: Editable,
    changeStart: Int,
    changeEnd: Int,
    previousTextLength: Int,
    deletedAlignmentPlaceholder: Boolean = false,
  ) {
    val spannable = editable as? SpannableStringBuilder ?: return

    if (spannable.isEmpty()) {
      typingAlignment = Layout.Alignment.ALIGN_NORMAL
      return
    }

    if (spannable.length < previousTextLength) {
      if (!deletedAlignmentPlaceholder && typingAlignment != Layout.Alignment.ALIGN_NORMAL) {
        val cursorPos = changeStart.coerceIn(0, spannable.length)
        val (pStart, pEnd) = spannable.getParagraphBounds(cursorPos, cursorPos)
        if (pStart == pEnd &&
          getParagraphAlignment(spannable, pStart, pEnd) == Layout.Alignment.ALIGN_NORMAL &&
          !paragraphHasListSpan(spannable, pStart, pEnd)
        ) {
          runAsATransaction {
            spannable.insert(pStart, EnrichedConstants.ZWS_STRING)
            spannable.setSpan(
              EnrichedAlignmentPlaceholderSpan(),
              pStart,
              pStart + 1,
              Spanned.SPAN_EXCLUSIVE_EXCLUSIVE,
            )
            spannable.setSpan(
              AlignmentSpan.Standard(typingAlignment),
              pStart,
              pStart + 1,
              Spanned.SPAN_EXCLUSIVE_EXCLUSIVE,
            )
          }
          setSelection(pStart + 1)
          layoutManager.invalidateLayout()
          requestLayout()
          invalidate()
        }
      }
      return
    }

    val safeStart = changeStart.coerceIn(0, spannable.length)
    val safeEnd = changeEnd.coerceIn(safeStart, spannable.length)
    if (safeStart >= safeEnd) return

    val alignment = typingAlignment
    var changedAlignment = ensureAlignedEmptyParagraphPlaceholders(spannable, safeStart, safeEnd)
    var index = safeStart
    while (index < safeEnd) {
      if (spannable[index] == '\n') {
        index++
        continue
      }

      val (paragraphStart, paragraphEnd) = spannable.getParagraphBounds(index, index)

      if (paragraphHasListSpan(spannable, paragraphStart, paragraphEnd)) {
        if (ensureParagraphAlignmentSpan(spannable, paragraphStart, paragraphEnd, alignment)) {
          changedAlignment = true
        }
        index = if (paragraphEnd > index) paragraphEnd else index + 1
        continue
      }

      val hadPlaceholder = removeLeadingAlignmentPlaceholderIfNeeded(spannable, paragraphStart, paragraphEnd)
      val adjustedParagraphEnd =
        if (hadPlaceholder) {
          (paragraphEnd - 1).coerceAtLeast(paragraphStart)
        } else {
          paragraphEnd
        }
      val alignmentChanged = ensureParagraphAlignmentSpan(spannable, paragraphStart, adjustedParagraphEnd, alignment)
      if (hadPlaceholder || alignmentChanged) {
        changedAlignment = true
      }

      index = if (adjustedParagraphEnd > index) adjustedParagraphEnd else index + 1
    }

    typingAlignment = alignment
    if (changedAlignment) {
      layoutManager.invalidateLayout()
      requestLayout()
      invalidate()
      post {
        val currentText = text as? Spannable ?: return@post
        val cursor = selectionStart.coerceIn(0, currentText.length)

        if (cursor < currentText.length &&
          currentText[cursor] == EnrichedConstants.ZWS &&
          currentText.getSpans(cursor, cursor + 1, EnrichedAlignmentPlaceholderSpan::class.java).isNotEmpty()
        ) {
          val newCursor = (cursor + 1).coerceAtMost(currentText.length)
          setSelection(newCursor)
          bringPointIntoView(newCursor)
          return@post
        }

        bringPointIntoView(cursor)
      }
    }
  }

  fun syncTypingAlignmentWithSelection(
    selStart: Int = selectionStart,
    selEnd: Int = selectionEnd,
  ) {
    val spannable = text as? Spannable ?: run {
      typingAlignment = Layout.Alignment.ALIGN_NORMAL
      return
    }

    if (spannable.isEmpty()) {
      typingAlignment = Layout.Alignment.ALIGN_NORMAL
      return
    }

    val safeStart = selStart.coerceIn(0, spannable.length)
    val safeEnd = selEnd.coerceIn(0, spannable.length)
    val resolved = resolveTypingAlignmentForSelection(spannable, safeStart, safeEnd)

    // Preserve explicit typing alignment during edits/newline creation.
    // Selection changes can happen before paragraph alignment spans are applied,
    // and we must not downgrade a non-left typingAlignment back to left because of that.
    if (typingAlignment != Layout.Alignment.ALIGN_NORMAL && resolved == Layout.Alignment.ALIGN_NORMAL) {
      return
    }

    typingAlignment = resolved
  }

  private fun resolveTypingAlignmentForSelection(
    spannable: Spannable,
    start: Int,
    end: Int,
  ): Layout.Alignment {
    val anchor =
      when {
        start < spannable.length -> start
        start > 0 -> start - 1
        else -> 0
      }
    val (paragraphStart, paragraphEnd) = spannable.getParagraphBounds(anchor, anchor)
    val paragraphAlignment = getParagraphAlignment(spannable, paragraphStart, paragraphEnd)
    if (paragraphAlignment != Layout.Alignment.ALIGN_NORMAL || paragraphStart < paragraphEnd || end > start) {
      return paragraphAlignment
    }

    if (paragraphStart > 0) {
      val (previousStart, previousEnd) = spannable.getParagraphBounds(paragraphStart - 1, paragraphStart - 1)
      return getParagraphAlignment(spannable, previousStart, previousEnd)
    }

    return Layout.Alignment.ALIGN_NORMAL
  }

  internal fun getParagraphAlignment(
    spannable: Spannable,
    start: Int,
    end: Int,
  ): Layout.Alignment {
    val spans = spannable.getSpans(start, end, AlignmentSpan::class.java)
    return spans.firstOrNull()?.alignment ?: Layout.Alignment.ALIGN_NORMAL
  }

  private fun removeAlignmentSpans(
    spannable: Spannable,
    start: Int,
    end: Int,
  ) {
    val spans = spannable.getSpans(start, end, AlignmentSpan::class.java)
    for (span in spans) {
      spannable.removeSpan(span)
    }
  }

  private fun ensureParagraphAlignmentSpan(
    spannable: SpannableStringBuilder,
    paragraphStart: Int,
    paragraphEnd: Int,
    alignment: Layout.Alignment,
  ): Boolean {
    if (alignment == Layout.Alignment.ALIGN_NORMAL) return false
    if (paragraphStart >= paragraphEnd) return false

    val existing = spannable.getSpans(paragraphStart, paragraphEnd, AlignmentSpan::class.java)
      .firstOrNull()

    if (existing == null || existing.alignment != alignment) {
      runAsATransaction {
        removeAlignmentSpans(spannable, paragraphStart, paragraphEnd)
        spannable.setSpan(
          AlignmentSpan.Standard(alignment),
          paragraphStart,
          paragraphEnd,
          Spanned.SPAN_EXCLUSIVE_EXCLUSIVE,
        )
      }
      return true
    }

    val spanStart = spannable.getSpanStart(existing)
    val spanEnd = spannable.getSpanEnd(existing)
    if (spanStart == paragraphStart && spanEnd >= paragraphEnd) return false

    // Grow/shrink to exactly the paragraph bounds (excludes trailing '\n')
    runAsATransaction {
      val flags = spannable.getSpanFlags(existing)
      spannable.setSpan(existing, paragraphStart, paragraphEnd, flags)
    }
    return true
  }

  private fun paragraphHasListSpan(
    spannable: Spannable,
    start: Int,
    end: Int,
  ): Boolean =
    spannable.getSpans(start, end, EnrichedInputUnorderedListSpan::class.java).isNotEmpty() ||
      spannable.getSpans(start, end, EnrichedInputOrderedListSpan::class.java).isNotEmpty() ||
      spannable.getSpans(start, end, EnrichedInputCheckboxListSpan::class.java).isNotEmpty()



  /**
   * Applies the current [typingAlignment] to the given paragraph range.
   * Returns true if a ZWS character was inserted (changing text length by 1).
   * Callers are responsible for cursor positioning and layout invalidation.
   */
  fun applyTypingAlignmentToParagraphRange(
    paragraphStart: Int,
    paragraphEnd: Int,
    manageCursorExternally: Boolean = false,
  ): Boolean {
    val spannable = text as? SpannableStringBuilder ?: return false
    if (typingAlignment == Layout.Alignment.ALIGN_NORMAL) return false

    val (safeStart, safeEnd) = spannable.getSafeSpanBoundaries(paragraphStart, paragraphEnd)

    if (safeStart >= safeEnd) {
      runAsATransaction {
        spannable.insert(safeStart, EnrichedConstants.ZWS_STRING)
        spannable.setSpan(
          EnrichedAlignmentPlaceholderSpan(),
          safeStart,
          safeStart + 1,
          Spanned.SPAN_EXCLUSIVE_EXCLUSIVE,
        )
        removeAlignmentSpans(spannable, safeStart, safeStart + 1)
        spannable.setSpan(
          AlignmentSpan.Standard(typingAlignment),
          safeStart,
          safeStart + 1,
          Spanned.SPAN_EXCLUSIVE_EXCLUSIVE,
        )
      }
      if (!manageCursorExternally) {
        setSelection(safeStart + 1)
      }
      if (!manageCursorExternally) {
        layoutManager.invalidateLayout()
        requestLayout()
        invalidate()
      }
      return true
    } else {
      runAsATransaction {
        removeAlignmentSpans(spannable, safeStart, safeEnd)
        spannable.setSpan(
          AlignmentSpan.Standard(typingAlignment),
          safeStart,
          safeEnd,
        Spanned.SPAN_EXCLUSIVE_EXCLUSIVE,
        )
      }
      if (!manageCursorExternally) {
        layoutManager.invalidateLayout()
        requestLayout()
        invalidate()
      }
      return false
    }
  }

  private fun ensureAlignedEmptyParagraphPlaceholders(
    spannable: SpannableStringBuilder,
    start: Int,
    end: Int,
  ): Boolean {
    val alignment = typingAlignment
    if (alignment == Layout.Alignment.ALIGN_NORMAL) return false

    var applied = false
    var index = start
    while (index < end && index < spannable.length) {
      if (spannable[index] != '\n') {
        index++
        continue
      }

      val paragraphStart = index + 1
      if (paragraphStart > spannable.length) break

      val (nextParagraphStart, nextParagraphEnd) = spannable.getParagraphBounds(paragraphStart, paragraphStart)
      if (nextParagraphStart == nextParagraphEnd && !paragraphHasListSpan(spannable, nextParagraphStart, nextParagraphEnd)) {
        runAsATransaction {
          spannable.insert(nextParagraphStart, EnrichedConstants.ZWS_STRING)
          spannable.setSpan(
            EnrichedAlignmentPlaceholderSpan(),
            nextParagraphStart,
            nextParagraphStart + 1,
            Spanned.SPAN_EXCLUSIVE_EXCLUSIVE,
          )
          removeAlignmentSpans(spannable, nextParagraphStart, nextParagraphStart + 1)
          spannable.setSpan(
            AlignmentSpan.Standard(alignment),
            nextParagraphStart,
            nextParagraphStart + 1,
            Spanned.SPAN_EXCLUSIVE_EXCLUSIVE,
          )
        }
        applied = true
      }

      index++
    }
    typingAlignment = alignment
    return applied
  }

  private fun removeLeadingAlignmentPlaceholderIfNeeded(
    spannable: SpannableStringBuilder,
    start: Int,
    end: Int,
  ): Boolean {
    if (start >= end) return false
    if (spannable[start] != EnrichedConstants.ZWS) return false
    if (end - start <= 1) return false
    if (paragraphHasListSpan(spannable, start, end)) return false
    val alignmentPlaceholderSpans = spannable.getSpans(start, start + 1, EnrichedAlignmentPlaceholderSpan::class.java)
    if (alignmentPlaceholderSpans.isEmpty()) return false

    runAsATransaction {
      spannable.delete(start, start + 1)
    }
    return true
  }

  private fun expandRangeToContiguousList(
    spannable: Spannable,
    start: Int,
    end: Int,
  ): Pair<Int, Int> {
    if (spannable.length == 0) return Pair(start, end)

    val listSpanClasses =
      listOf(
        EnrichedInputUnorderedListSpan::class.java,
        EnrichedInputOrderedListSpan::class.java,
        EnrichedInputCheckboxListSpan::class.java,
      )

    val (startParagraphStart, startParagraphEnd) = spannable.getParagraphBounds(start, start)
    val activeStartList =
      listSpanClasses.firstOrNull { clazz ->
        spannable.getSpans(startParagraphStart, startParagraphEnd, clazz).isNotEmpty()
      }

    var expandedStart = start
    if (activeStartList != null) {
      var currentStart = startParagraphStart
      while (currentStart > 0) {
        val (previousStart, previousEnd) = spannable.getParagraphBounds(currentStart - 1, currentStart - 1)
        if (spannable.getSpans(previousStart, previousEnd, activeStartList).isEmpty()) break
        expandedStart = previousStart
        currentStart = previousStart
      }
    }

    val endLocation = if (end > start) end - 1 else end
    val (endParagraphStart, endParagraphEnd) = spannable.getParagraphBounds(endLocation, endLocation)
    val activeEndList =
      listSpanClasses.firstOrNull { clazz ->
        spannable.getSpans(endParagraphStart, endParagraphEnd, clazz).isNotEmpty()
      }

    var expandedEnd = end
    if (activeEndList != null) {
      var currentStart = endParagraphStart
      while (currentStart < spannable.length) {
        val (nextStart, nextEnd) = spannable.getParagraphBounds(currentStart, currentStart)
        if (nextStart >= spannable.length) break
        if (spannable.getSpans(nextStart, nextEnd, activeEndList).isEmpty()) break
        expandedEnd = nextEnd.coerceAtMost(spannable.length)
        currentStart = nextEnd + 1
      }
    }

    return Pair(expandedStart, expandedEnd)
  }

  // https://github.com/facebook/react-native/blob/36df97f500aa0aa8031098caf7526db358b6ddc1/packages/react-native/ReactAndroid/src/main/java/com/facebook/react/views/textinput/ReactEditText.kt#L283C2-L284C1
  // After the text changes inside an EditText, TextView checks if a layout() has been requested.
  // If it has, it will not scroll the text to the end of the new text inserted, but wait for the
  // next layout() to be called. However, we do not perform a layout() after a requestLayout(), so
  // we need to override isLayoutRequested to force EditText to scroll to the end of the new text
  // immediately.
  override fun isLayoutRequested(): Boolean = false

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
      EnrichedSpans.CHECKBOX_LIST -> listStyles?.toggleStyle(EnrichedSpans.CHECKBOX_LIST)
      else -> Log.w(TAG, "Unknown style: $name")
    }

    layoutManager.invalidateLayout()
  }

  private fun removeStyle(
    name: String,
    start: Int,
    end: Int,
  ): Boolean {
    val removed =
      when (name) {
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
        EnrichedSpans.CHECKBOX_LIST -> listStyles?.removeStyle(EnrichedSpans.CHECKBOX_LIST, start, end)
        EnrichedSpans.LINK -> parametrizedStyles?.removeStyle(EnrichedSpans.LINK, start, end)
        EnrichedSpans.IMAGE -> parametrizedStyles?.removeStyle(EnrichedSpans.IMAGE, start, end)
        EnrichedSpans.MENTION -> parametrizedStyles?.removeStyle(EnrichedSpans.MENTION, start, end)
        else -> false
      }

    return removed == true
  }

  private fun getTargetRange(name: String): Pair<Int, Int> {
    val result =
      when (name) {
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
        EnrichedSpans.CHECKBOX_LIST -> listStyles?.getStyleRange()
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
      val finalEnd =
        if (charactersRemoved > 0) {
          (end - charactersRemoved).coerceAtLeast(0)
        } else {
          end
        }

      val finalStart = start.coerceAtLeast(0).coerceAtMost(finalEnd)
      selection?.onSelection(finalStart, finalEnd)
    }

    return true
  }

  fun verifyAndToggleStyle(name: String) {
    val isValid = verifyStyle(name)
    if (!isValid) return

    toggleStyle(name)
  }

  fun toggleCheckboxListItem(checked: Boolean) {
    val isValid = verifyStyle(EnrichedSpans.CHECKBOX_LIST)
    if (!isValid) return

    listStyles?.toggleCheckboxListStyle(checked)
  }

  fun addLink(
    start: Int,
    end: Int,
    text: String,
    url: String,
  ) {
    val isValid = verifyStyle(EnrichedSpans.LINK)
    if (!isValid) return

    parametrizedStyles?.setLinkSpan(getActualIndex(start), getActualIndex(end), text, url)
  }

  fun removeLink(
    start: Int,
    end: Int,
  ) {
    parametrizedStyles?.removeLinkSpans(getActualIndex(start), getActualIndex(end))
  }

  fun addImage(
    src: String,
    width: Float,
    height: Float,
  ) {
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

  fun addMention(
    indicator: String,
    text: String,
    attributes: Map<String, String>,
  ) {
    val isValid = verifyStyle(EnrichedSpans.MENTION)
    if (!isValid) return

    parametrizedStyles?.setMentionSpan(text, indicator, attributes)
  }

  fun requestHTML(requestId: Int) {
    val html =
      try {
        EnrichedParser.toHtmlWithDefault(text)
      } catch (_: Exception) {
        null
      }

    val reactContext = context as ReactContext
    val surfaceId = UIManagerHelper.getSurfaceId(reactContext)
    val dispatcher = UIManagerHelper.getEventDispatcherForReactTag(reactContext, id)
    dispatcher?.dispatchEvent(OnRequestHtmlResultEvent(surfaceId, id, requestId, html, experimentalSynchronousEvents))
  }

  // Sometimes setting up style triggers many changes in sequence
  // Eg. removing conflicting styles -> changing text -> applying spans
  // In such scenario we want to prevent from handling side effects (eg. onTextChanged)
  fun runAsATransaction(block: () -> Unit) {
    transactionDepth++
    try {
      block()
    } finally {
      transactionDepth = (transactionDepth - 1).coerceAtLeast(0)
    }
  }

  private fun forceScrollToSelection() {
    val textLayout = layout ?: return
    val cursorOffset = selectionStart
    if (cursorOffset <= 0) return

    val selectedLineIndex = textLayout.getLineForOffset(cursorOffset)
    val selectedLineTop = textLayout.getLineTop(selectedLineIndex)
    val selectedLineBottom = textLayout.getLineBottom(selectedLineIndex)
    val visibleTextHeight = height - paddingTop - paddingBottom

    if (visibleTextHeight <= 0) return

    val visibleTop = scrollY
    val visibleBottom = scrollY + visibleTextHeight
    var targetScrollY = scrollY

    if (selectedLineTop < visibleTop) {
      targetScrollY = selectedLineTop
    } else if (selectedLineBottom > visibleBottom) {
      targetScrollY = selectedLineBottom - visibleTextHeight
    }

    val maxScrollY = (textLayout.height - visibleTextHeight).coerceAtLeast(0)
    targetScrollY = targetScrollY.coerceIn(0, maxScrollY)
    scrollTo(0, targetScrollY)
  }

  private fun isHeadingBold(
    style: HtmlStyle,
    span: EnrichedInputSpan,
  ): Boolean =
    when (span) {
      is EnrichedInputH1Span -> style.h1Bold
      is EnrichedInputH2Span -> style.h2Bold
      is EnrichedInputH3Span -> style.h3Bold
      is EnrichedInputH4Span -> style.h4Bold
      is EnrichedInputH5Span -> style.h5Bold
      is EnrichedInputH6Span -> style.h6Bold
      else -> false
    }

  private fun shouldRemoveBoldFromHeading(
    span: EnrichedInputSpan,
    prevStyle: HtmlStyle,
    nextStyle: HtmlStyle,
  ): Boolean {
    val wasBold = isHeadingBold(prevStyle, span)
    val isNowBold = isHeadingBold(nextStyle, span)

    return !wasBold && isNowBold
  }

  private fun reApplyHtmlStyleForSpans(
    previousHtmlStyle: HtmlStyle,
    nextHtmlStyle: HtmlStyle,
  ) {
    val spannable = text as? Spannable ?: return
    if (spannable.isEmpty()) return

    var shouldEmitStateChange = false

    runAsATransaction {
      val spans = spannable.getSpans(0, spannable.length, EnrichedInputSpan::class.java)
      for (span in spans) {
        if (!span.dependsOnHtmlStyle) continue

        val start = spannable.getSpanStart(span)
        val end = spannable.getSpanEnd(span)
        val flags = spannable.getSpanFlags(span)

        if (start == -1 || end == -1) continue

        // Check if we need to remove explicit bold spans
        if (shouldRemoveBoldFromHeading(span, previousHtmlStyle, nextHtmlStyle)) {
          val isRemoved = removeStyle(EnrichedSpans.BOLD, start, end)
          if (isRemoved) shouldEmitStateChange = true
        }

        spannable.removeSpan(span)
        val newSpan = span.rebuildWithStyle(htmlStyle)
        spannable.setSpan(newSpan, start, end, flags)
      }

      if (shouldEmitStateChange) {
        selection?.validateStyles()
      }
    }
    layoutManager.invalidateLayout()
    forceScrollToSelection()
  }

  override fun onAttachedToWindow() {
    super.onAttachedToWindow()

    // https://github.com/facebook/react-native/blob/36df97f500aa0aa8031098caf7526db358b6ddc1/packages/react-native/ReactAndroid/src/main/java/com/facebook/react/views/textinput/ReactEditText.kt#L946
    // setTextIsSelectable internally calls setText(), which fires afterTextChanged that should be marked as a transaction to avoid unwanted side effects
    runAsATransaction { super.setTextIsSelectable(true) }

    if (autoFocus && !didAttachToWindow) {
      requestFocusProgrammatically()
    }

    didAttachToWindow = true
  }

  companion object {
    const val TAG = "EnrichedTextInputView"
    const val CLIPBOARD_TAG = "react-native-enriched-clipboard"
    private const val CONTEXT_MENU_ITEM_ID = 10000
  }
}
