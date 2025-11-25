package com.swmansion.enriched.styles

import android.net.Uri
import android.text.Editable
import android.text.Spannable
import android.text.SpannableStringBuilder
import android.text.Spanned
import com.swmansion.enriched.EnrichedTextInputView
import com.swmansion.enriched.spans.EnrichedImageSpan
import com.swmansion.enriched.spans.EnrichedLinkSpan
import com.swmansion.enriched.spans.EnrichedMentionSpan
import com.swmansion.enriched.spans.EnrichedSpans
import com.swmansion.enriched.utils.getSafeSpanBoundaries
import java.io.File

class ParametrizedStyles(private val view: EnrichedTextInputView) {
  private var mentionStart: Int? = null
  private var isSettingLinkSpan = false

  var mentionIndicators: Array<String> = emptyArray<String>()

  fun <T>removeSpansForRange(spannable: Spannable, start: Int, end: Int, clazz: Class<T>): Boolean {
    val ssb = spannable as SpannableStringBuilder
    val spans = ssb.getSpans(start, end, clazz)
    if (spans.isEmpty()) return false

    ssb.replace(start, end, ssb.substring(start, end).replace("\u200B", ""))

    for (span in spans) {
      ssb.removeSpan(span)
    }

    return true
  }

  fun setLinkSpan(start: Int, end: Int, text: String, url: String) {
    isSettingLinkSpan = true

    val spannable = view.text as SpannableStringBuilder
    val spans = spannable.getSpans(start, end, EnrichedLinkSpan::class.java)
    for (span in spans) {
      spannable.removeSpan(span)
    }

    if (start == end) {
      spannable.insert(start, text)
    } else {
      spannable.replace(start, end, text)
    }

    val spanEnd = start + text.length
    val span = EnrichedLinkSpan(url, view.htmlStyle)
    val (safeStart, safeEnd) = spannable.getSafeSpanBoundaries(start, spanEnd)
    spannable.setSpan(span, safeStart, safeEnd, Spanned.SPAN_EXCLUSIVE_EXCLUSIVE)

    view.selection?.validateStyles()
    isSettingLinkSpan = false
  }

  fun afterTextChanged(s: Editable, endCursorPosition: Int) {
    val result = getWordAtIndex(s, endCursorPosition) ?: return

    afterTextChangedLinks(result)
    afterTextChangedMentions(result)
  }

  fun detectAllLinks() {
    val spannable = view.text as Spannable

    // TODO: Consider using more reliable regex, this one matches almost anything
    val urlPattern = android.util.Patterns.WEB_URL.matcher(spannable)

    val spans = spannable.getSpans(0, spannable.length, EnrichedLinkSpan::class.java)
    for (span in spans) {
      spannable.removeSpan(span)
    }

    while (urlPattern.find()) {
      val word = urlPattern.group()
      val start = urlPattern.start()
      val end = urlPattern.end()
      val span = EnrichedLinkSpan(word, view.htmlStyle)
      val (safeStart, safeEnd) = spannable.getSafeSpanBoundaries(start, end)
      spannable.setSpan(span, safeStart, safeEnd, Spanned.SPAN_EXCLUSIVE_EXCLUSIVE)
    }
  }

  private fun getWordAtIndex(s: Editable, index: Int): Triple<String, Int, Int>? {
    if (index < 0 ) return null

    var start = index
    var end = index

    while (start > 0 && !Character.isWhitespace(s[start - 1])) {
      start--
    }

    while (end < s.length && !Character.isWhitespace(s[end])) {
      end++
    }

    val result = s.subSequence(start, end).toString()

    return Triple(result, start, end)
  }

  private fun canLinkBeApplied(): Boolean {
    val mergingConfig = EnrichedSpans.getMergingConfigForStyle(EnrichedSpans.LINK, view.htmlStyle)?: return true
    val conflictingStyles = mergingConfig.conflictingStyles
    val blockingStyles = mergingConfig.blockingStyles

    for (style in blockingStyles) {
      if (view.spanState?.getStart(style) != null) return false
    }

    for (style in conflictingStyles) {
      if (view.spanState?.getStart(style) != null) return false
    }

    return true
  }

  private fun afterTextChangedLinks(result: Triple<String, Int, Int>) {
    // Do not detect link if it's applied manually
    if (isSettingLinkSpan || !canLinkBeApplied()) return

    val spannable = view.text as Spannable
    val (word, start, end) = result

    // TODO: Consider using more reliable regex, this one matches almost anything
    val urlPattern = android.util.Patterns.WEB_URL.matcher(word)
    val spans = spannable.getSpans(start, end, EnrichedLinkSpan::class.java)
    for (span in spans) {
      spannable.removeSpan(span)
    }

    if (urlPattern.matches()) {
      val span = EnrichedLinkSpan(word, view.htmlStyle)
      val (safeStart, safeEnd) = spannable.getSafeSpanBoundaries(start, end)
      spannable.setSpan(span, safeStart, safeEnd, Spanned.SPAN_EXCLUSIVE_EXCLUSIVE)
    }
  }

  private fun afterTextChangedMentions(result: Triple<String, Int, Int>) {
    val mentionHandler = view.mentionHandler ?: return
    val spannable = view.text as Spannable
    val (word, start, end) = result

    val indicatorsPattern = mentionIndicators.joinToString("|") { Regex.escape(it) }
    val mentionIndicatorRegex = Regex("^($indicatorsPattern)")
    val mentionRegex= Regex("^($indicatorsPattern)\\w*")

    val spans = spannable.getSpans(start, end, EnrichedMentionSpan::class.java)
    for (span in spans) {
      spannable.removeSpan(span)
    }

    if (mentionRegex.matches(word)) {
      val indicator = mentionIndicatorRegex.find(word)?.value ?: ""
      val text = word.replaceFirst(indicator, "")

      // Means we are starting mention
      if (text.isEmpty()) {
        mentionStart = start
      }

      mentionHandler.onMention(indicator, text)
    } else {
      mentionHandler.endMention()
    }
  }

  fun setImageSpan(src: String, width: Float, height: Float) {
    if (view.selection == null) return

    val spannable = view.text as SpannableStringBuilder
    var (start, end) = view.selection.getInlineSelection()
    val spans = spannable.getSpans(start, end, EnrichedImageSpan::class.java)

    for (s in spans) {
      spannable.removeSpan(s)
    }

    if (start == end) {
      spannable.insert(start, "\uFFFC")
      end++
    }

    val uri = Uri.fromFile(File(src))

    val span = EnrichedImageSpan(view.context, uri, width.toInt(), height.toInt())
    val (safeStart, safeEnd) = spannable.getSafeSpanBoundaries(start, end)
    spannable.setSpan(span, safeStart, safeEnd, Spannable.SPAN_EXCLUSIVE_EXCLUSIVE)
  }

  fun startMention(indicator: String) {
    val selection = view.selection ?: return

    val spannable = view.text as SpannableStringBuilder
    val (start, end) = selection.getInlineSelection()

    if (start == end) {
      spannable.insert(start, indicator)
    } else {
      spannable.replace(start, end, indicator)
    }
  }

  fun setMentionSpan(indicator: String, text: String, attributes: Map<String, String>) {
    val selection = view.selection ?: return

    val spannable = view.text as SpannableStringBuilder
    val (selectionStart, selectionEnd) = selection.getInlineSelection()
    val spans = spannable.getSpans(selectionStart, selectionEnd, EnrichedMentionSpan::class.java)

    for (span in spans) {
      spannable.removeSpan(span)
    }

    val start = mentionStart ?: return

    view.runAsATransaction {
      spannable.replace(start, selectionEnd, text)

      val span = EnrichedMentionSpan(text, indicator, attributes, view.htmlStyle)
      val spanEnd = start + text.length
      val (safeStart, safeEnd) = spannable.getSafeSpanBoundaries(start, spanEnd)
      spannable.setSpan(span, safeStart, safeEnd, Spanned.SPAN_EXCLUSIVE_EXCLUSIVE)

      val hasSpaceAtTheEnd = spannable.length > safeEnd && spannable[safeEnd] == ' '
      if (!hasSpaceAtTheEnd) {
        spannable.insert(safeEnd, " ")
      }
    }

    view.mentionHandler?.reset()
    view.selection.validateStyles()
  }

  fun getStyleRange(): Pair<Int, Int> {
    return view.selection?.getInlineSelection() ?: Pair(0, 0)
  }

  fun removeStyle(name: String, start: Int, end: Int): Boolean {
    val config = EnrichedSpans.parametrizedStyles[name] ?: return false
    val spannable = view.text as Spannable
    return removeSpansForRange(spannable, start, end, config.clazz)
  }
}
