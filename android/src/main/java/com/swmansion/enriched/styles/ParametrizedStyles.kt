package com.swmansion.enriched.styles

import android.text.Editable
import android.text.Spannable
import android.text.SpannableStringBuilder
import android.text.Spanned
import com.swmansion.enriched.EnrichedTextInputView
import com.swmansion.enriched.spans.EnrichedImageSpan
import com.swmansion.enriched.spans.EnrichedLinkSpan
import com.swmansion.enriched.spans.EnrichedMentionSpan
import com.swmansion.enriched.spans.EnrichedSpans
import com.swmansion.enriched.utils.EnrichedConstants
import com.swmansion.enriched.utils.getSafeSpanBoundaries
import com.swmansion.enriched.utils.removeZWS

class ParametrizedStyles(
  private val view: EnrichedTextInputView,
) {
  private var mentionStart: Int? = null
  private var isSettingLinkSpan = false

  var mentionIndicators: Array<String> = emptyArray<String>()

  fun <T> removeSpansForRange(
    spannable: Spannable,
    start: Int,
    end: Int,
    clazz: Class<T>,
  ): Boolean {
    val ssb = spannable as SpannableStringBuilder
    val spans = ssb.getSpans(start, end, clazz)
    if (spans.isEmpty()) return false

    ssb.removeZWS(start, end)

    for (span in spans) {
      ssb.removeSpan(span)
    }

    return true
  }

  fun setLinkSpan(
    start: Int,
    end: Int,
    text: String,
    url: String,
  ) {
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

  fun afterTextChanged(
    s: Editable,
    startCursorPosition: Int,
    endCursorPosition: Int,
  ) {
    afterTextChangedLinks(startCursorPosition, endCursorPosition)
    afterTextChangedMentions(s, startCursorPosition)
  }

  fun detectAllLinks() {
    val regex = view.linkRegex ?: return
    val spannable = view.text as Spannable
    val urlPattern = regex.matcher(spannable)

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

  private fun getWordAtIndex(
    s: CharSequence,
    index: Int,
  ): TextRange? {
    if (index < 0) return null

    var start = index
    var end = index

    while (start > 0 && !Character.isWhitespace(s[start - 1])) {
      start--
    }

    while (end < s.length && !Character.isWhitespace(s[end])) {
      end++
    }

    val result = s.subSequence(start, end).toString()

    return TextRange(result, start, end)
  }

  // After editing text we want to automatically detect links in the affected range
  // Affected range is range + previous word + next word
  private fun getLinksAffectedRange(
    s: CharSequence,
    start: Int,
    end: Int,
  ): IntRange {
    var actualStart = start
    var actualEnd = end

    // Expand backward to find the start of the first affected word
    while (actualStart > 0 && !Character.isWhitespace(s[actualStart - 1])) {
      actualStart--
    }

    // Expand forward to find the end of the last affected word
    while (actualEnd < s.length && !Character.isWhitespace(s[actualEnd])) {
      actualEnd++
    }

    return actualStart..actualEnd
  }

  private fun canLinkBeApplied(): Boolean {
    val mergingConfig = EnrichedSpans.getMergingConfigForStyle(EnrichedSpans.LINK, view.htmlStyle) ?: return true
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

  private fun afterTextChangedLinks(
    editStart: Int,
    editEnd: Int,
  ) {
    val regex = view.linkRegex ?: return

    // Do not detect link if it's applied manually
    if (isSettingLinkSpan || !canLinkBeApplied()) return

    val spannable = view.text as? Spannable ?: return
    val affectedRange = getLinksAffectedRange(spannable, editStart, editEnd)
    val contextText = spannable.subSequence(affectedRange.first, affectedRange.last).toString()

    val spans = spannable.getSpans(affectedRange.first, affectedRange.last, EnrichedLinkSpan::class.java)
    for (span in spans) {
      spannable.removeSpan(span)
    }

    val wordsRegex = Regex("\\S+")
    for (wordMatch in wordsRegex.findAll(contextText)) {
      var word = wordMatch.value
      var wordStart = wordMatch.range.first

      // Do not include zero-width space in link detection
      if (word.startsWith("\u200B")) {
        word = word.substring(1)
        wordStart += 1
      }

      // Loop over words and detect links
      val matcher = regex.matcher(word)
      while (matcher.find()) {
        val linkStart = matcher.start()
        val linkEnd = matcher.end()

        val spanStart = affectedRange.first + wordStart + linkStart
        val spanEnd = affectedRange.first + wordStart + linkEnd

        val span = EnrichedLinkSpan(matcher.group(), view.htmlStyle)
        val (safeStart, safeEnd) = spannable.getSafeSpanBoundaries(spanStart, spanEnd)

        spannable.setSpan(
          span,
          safeStart,
          safeEnd,
          Spanned.SPAN_EXCLUSIVE_EXCLUSIVE,
        )
      }
    }
  }

  private fun afterTextChangedMentions(
    s: CharSequence,
    endCursorPosition: Int,
  ) {
    val mentionHandler = view.mentionHandler ?: return
    val currentWord = getWordAtIndex(s, endCursorPosition) ?: return
    val spannable = view.text as Spannable

    val indicatorsPattern = mentionIndicators.joinToString("|") { Regex.escape(it) }
    val mentionIndicatorRegex = Regex("^($indicatorsPattern)")
    val mentionRegex = Regex("^($indicatorsPattern)\\w*")

    val spans = spannable.getSpans(currentWord.start, currentWord.end, EnrichedMentionSpan::class.java)
    for (span in spans) {
      spannable.removeSpan(span)
    }

    var indicator: String
    var finalStart: Int
    val finalEnd = currentWord.end

    // No mention in the current word, check previous one
    if (!mentionRegex.matches(currentWord.text)) {
      val previousWord = getWordAtIndex(spannable, currentWord.start - 1)

      // No previous word -> no mention to be detected
      if (previousWord == null) {
        mentionHandler.endMention()
        return
      }

      // Previous word is not a mention -> end mention
      if (!mentionRegex.matches(previousWord.text)) {
        mentionHandler.endMention()
        return
      }

      // Previous word is a mention -> use it
      finalStart = previousWord.start
      indicator = mentionIndicatorRegex.find(previousWord.text)?.value ?: ""
    } else {
      // Current word is a mention -> use it
      finalStart = currentWord.start
      indicator = mentionIndicatorRegex.find(currentWord.text)?.value ?: ""
    }

    // Extract text without indicator
    val text = spannable.subSequence(finalStart, finalEnd).toString().replaceFirst(indicator, "")

    // Means we are starting mention
    if (text.isEmpty()) {
      mentionStart = finalStart
    }

    mentionHandler.onMention(indicator, text)
  }

  fun setImageSpan(
    src: String,
    width: Float,
    height: Float,
  ) {
    if (view.selection == null) return
    val spannable = view.text as SpannableStringBuilder
    val (start, originalEnd) = view.selection.getInlineSelection()

    if (start == originalEnd) {
      spannable.insert(start, EnrichedConstants.ORC.toString())
    } else {
      val spans = spannable.getSpans(start, originalEnd, EnrichedImageSpan::class.java)
      for (s in spans) {
        spannable.removeSpan(s)
      }

      spannable.replace(start, originalEnd, EnrichedConstants.ORC.toString())
    }

    val (imageStart, imageEnd) = spannable.getSafeSpanBoundaries(start, start + 1)
    val span = EnrichedImageSpan.createEnrichedImageSpan(src, width.toInt(), height.toInt())
    span.observeAsyncDrawableLoaded(view.text)

    spannable.setSpan(span, imageStart, imageEnd, Spannable.SPAN_EXCLUSIVE_EXCLUSIVE)
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

  fun setMentionSpan(
    indicator: String,
    text: String,
    attributes: Map<String, String>,
  ) {
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

  fun getStyleRange(): Pair<Int, Int> = view.selection?.getInlineSelection() ?: Pair(0, 0)

  fun removeStyle(
    name: String,
    start: Int,
    end: Int,
  ): Boolean {
    val config = EnrichedSpans.parametrizedStyles[name] ?: return false
    val spannable = view.text as Spannable
    return removeSpansForRange(spannable, start, end, config.clazz)
  }

  companion object {
    data class TextRange(
      val text: String,
      val start: Int,
      val end: Int,
    )
  }
}
