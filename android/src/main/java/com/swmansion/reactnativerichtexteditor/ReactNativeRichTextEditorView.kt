package com.swmansion.reactnativerichtexteditor

import android.content.Context
import android.graphics.Color
import android.text.Spannable
import android.text.StaticLayout
import android.text.method.LinkMovementMethod
import android.util.AttributeSet
import android.util.Log
import android.util.TypedValue
import androidx.appcompat.widget.AppCompatEditText
import com.facebook.react.bridge.Arguments
import com.facebook.react.common.ReactConstants
import com.facebook.react.uimanager.PixelUtil
import com.facebook.react.uimanager.StateWrapper
import com.facebook.react.views.text.ReactTypefaceUtils.applyStyles
import com.facebook.react.views.text.ReactTypefaceUtils.parseFontStyle
import com.facebook.react.views.text.ReactTypefaceUtils.parseFontWeight
import com.swmansion.reactnativerichtexteditor.events.LinkHandler
import com.swmansion.reactnativerichtexteditor.events.MentionHandler
import com.swmansion.reactnativerichtexteditor.spans.EditorSpans
import com.swmansion.reactnativerichtexteditor.styles.InlineStyles
import com.swmansion.reactnativerichtexteditor.styles.ListStyles
import com.swmansion.reactnativerichtexteditor.styles.ParagraphStyles
import com.swmansion.reactnativerichtexteditor.styles.SpecialStyles
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
  val specialStyles: SpecialStyles? = SpecialStyles(this)
  var isSettingDefaultValue: Boolean = false

  var linkHandler: LinkHandler? = LinkHandler(this)
  val mentionHandler: MentionHandler? = MentionHandler(this)

  private var typefaceDirty = false
  private var fontSize: Float? = null
  private var fontFamily: String? = null
  private var fontStyle: Int = ReactConstants.UNSET
  private var fontWeight: Int = ReactConstants.UNSET
  private var forceHeightRecalculationCounter: Int = 0

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

  private fun prepareComponent() {
    this.isSingleLine = false
    this.isHorizontalScrollBarEnabled = false
    this.gravity = android.view.Gravity.CENTER or android.view.Gravity.START
    // required to make ClickableSpans really clickable
    this.movementMethod = LinkMovementMethod.getInstance()

    this.setPadding(0, 0, 0, 0)
    this.setBackgroundColor(Color.TRANSPARENT)

    addSpanWatcher(EditorSpanWatcher(this))
    addTextChangedListener(EditorTextWatcher(this))
  }

  override fun onSelectionChanged(selStart: Int, selEnd: Int) {
    super.onSelectionChanged(selStart, selEnd)
    selection?.onSelection(selStart, selEnd)
  }

  fun setStateWrapper(stateWrapper: StateWrapper?) {
    this.stateWrapper = stateWrapper
  }

  fun setDefaultValue(value: String?) {
    if (value == null) return
    isSettingDefaultValue = true

    val isHtml = value.startsWith("<html>") && value.endsWith("</html>")
    if (isHtml) {
      val parsed = EditorParser.fromHtml(value, EditorParser.FROM_HTML_MODE_COMPACT, null, null, linkHandler, mentionHandler)
      setText(parsed)
    } else {
      setText(value)
    }

    // Assign SpanWatcher one more time as our previous spannable has been replaced
    addSpanWatcher(EditorSpanWatcher(this))

    isSettingDefaultValue = false
  }

  fun setColor(colorInt: Int?) {
    if (colorInt == null) {
      this.setTextColor(Color.BLACK)
      return
    }

    this.setTextColor(colorInt)
  }

  fun setFontSize(size: Float) {
    if (size == 0f) return

    val sizeInt = ceil(PixelUtil.toPixelFromSP(size))
    fontSize = sizeInt
    setTextSize(TypedValue.COMPLEX_UNIT_PX, sizeInt)

    updateYogaState()
  }

  fun setFontFamily(family: String?) {
    if (family != this.fontFamily) {
      this.fontFamily = family
      typefaceDirty = true
    }
  }

  fun setFontWeight(weight: String?) {
    val fontWeight = parseFontWeight(weight)

    if (fontWeight != this.fontStyle) {
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

  fun measureSize(maxWidth: Float): Pair<Float, Float> {
    val paint = this.paint
    val spannable = this.text as Spannable
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

  fun addLink(text: String, url: String) {
    val isValid = verifyStyle(EditorSpans.LINK)
    if (!isValid) return

    specialStyles?.setLinkSpan(text, url)
  }

  fun addImage(src: String) {
    val isValid = verifyStyle(EditorSpans.IMAGE)
    if (!isValid) return

    specialStyles?.setImageSpan(src)
  }

  fun startMention() {
    val isValid = verifyStyle(EditorSpans.MENTION)
    if (!isValid) return

    specialStyles?.startMention()
  }

  fun addMention(text: String, value: String) {
    val isValid = verifyStyle(EditorSpans.MENTION)
    if (!isValid) return

    specialStyles?.setMentionSpan(text, value)
  }

  // Update shadow node's state in order to recalculate layout
  fun updateYogaState() {
    val counter = forceHeightRecalculationCounter
    forceHeightRecalculationCounter++
    val state = Arguments.createMap()

    state.putInt("forceHeightRecalculationCounter", counter)
    stateWrapper?.updateState(state)
  }

  override fun onDetachedFromWindow() {
    forceHeightRecalculationCounter = 0

    super.onDetachedFromWindow()
  }
}
