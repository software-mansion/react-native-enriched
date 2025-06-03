package com.swmansion.reactnativerichtexteditor.styles

import android.net.Uri
import android.text.Editable
import android.text.Spannable
import android.text.SpannableStringBuilder
import android.text.Spanned
import com.swmansion.reactnativerichtexteditor.ReactNativeRichTextEditorView
import com.swmansion.reactnativerichtexteditor.spans.EditorImageSpan
import com.swmansion.reactnativerichtexteditor.spans.EditorLinkSpan
import com.swmansion.reactnativerichtexteditor.spans.EditorMentionSpan
import com.swmansion.reactnativerichtexteditor.utils.getSafeSpanBoundaries
import java.io.File

class ParametrizedStyles(private val editorView: ReactNativeRichTextEditorView) {
  private var mentionStart: Int? = null
  var mentionIndicators: Array<String> = emptyArray<String>()

  fun setLinkSpan(start: Int, end: Int, text: String, url: String) {
    val spannable = editorView.text as SpannableStringBuilder
    val spans = spannable.getSpans(start, end, EditorLinkSpan::class.java)
    for (span in spans) {
      spannable.removeSpan(span)
    }

    if (start == end) {
      spannable.insert(start, text)
    } else {
      spannable.replace(start, end, text)
    }

    val spanEnd = start + text.length
    val span = EditorLinkSpan(url, editorView.richTextStyle)
    val (safeStart, safeEnd) = spannable.getSafeSpanBoundaries(start, spanEnd)
    spannable.setSpan(span, safeStart, safeEnd, Spanned.SPAN_EXCLUSIVE_EXCLUSIVE)

    editorView.selection?.validateStyles()
  }

  fun afterTextChanged(s: Editable, endCursorPosition: Int) {
    val result = getWordAtIndex(s, endCursorPosition) ?: return

    afterTextChangedLinks(result)
    afterTextChangedMentions(result)
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

  private fun afterTextChangedLinks(result: Triple<String, Int, Int>) {
    val spannable = editorView.text as Spannable
    val (word, start, end) = result

    // TODO: Consider using more reliable regex, this one matches almost anything
    val urlPattern = android.util.Patterns.WEB_URL.matcher(word)

    val spans = spannable.getSpans(start, end, EditorLinkSpan::class.java)
    for (span in spans) {
      spannable.removeSpan(span)
    }

    if (urlPattern.matches()) {
      val span = EditorLinkSpan(word, editorView.richTextStyle)
      val (safeStart, safeEnd) = spannable.getSafeSpanBoundaries(start, end)
      spannable.setSpan(span, safeStart, safeEnd, Spanned.SPAN_EXCLUSIVE_EXCLUSIVE)
    }
  }

  private fun afterTextChangedMentions(result: Triple<String, Int, Int>) {
    val mentionHandler = editorView.mentionHandler ?: return
    val spannable = editorView.text as Spannable
    val (word, start, end) = result

    val indicatorsPattern = mentionIndicators.joinToString("|") { Regex.escape(it) }
    val mentionIndicatorRegex = Regex("^($indicatorsPattern)")
    val mentionRegex= Regex("^($indicatorsPattern)\\w*")

    val spans = spannable.getSpans(start, end, EditorMentionSpan::class.java)
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

      mentionHandler.onMention(indicator, word.replaceFirst(indicator, ""))
    } else {
      mentionHandler.endMention()
    }
  }

  fun setImageSpan(src: String) {
    if (editorView.selection == null) return

    val spannable = editorView.text as SpannableStringBuilder
    var (start, end) = editorView.selection.getInlineSelection()
    val spans = spannable.getSpans(start, end, EditorImageSpan::class.java)

    for (s in spans) {
      spannable.removeSpan(s)
    }

    if (start == end) {
      spannable.insert(start, "\uFFFC")
      end++
    }

    val uri = Uri.fromFile(File(src))
    val span = EditorImageSpan(editorView.context, uri, editorView.richTextStyle)
    val (safeStart, safeEnd) = spannable.getSafeSpanBoundaries(start, end)
    spannable.setSpan(span, safeStart, safeEnd, Spannable.SPAN_EXCLUSIVE_EXCLUSIVE)
  }

  fun startMention(indicator: String) {
    val selection = editorView.selection ?: return

    val spannable = editorView.text as SpannableStringBuilder
    var (start, end) = selection.getInlineSelection()

    if (start == end) {
      spannable.insert(start, indicator)
    } else {
      spannable.replace(start, end, indicator)
    }
  }

  fun setMentionSpan(text: String, attributes: Map<String, String>) {
    val selection = editorView.selection ?: return

    val spannable = editorView.text as SpannableStringBuilder
    var (selectionStart, selectionEnd) = selection.getInlineSelection()
    val spans = spannable.getSpans(selectionStart, selectionEnd, EditorMentionSpan::class.java)

    for (span in spans) {
      spannable.removeSpan(span)
    }

    var start = mentionStart ?: return
    spannable.replace(start, selectionEnd, text)

    val span = EditorMentionSpan(text, attributes, editorView.richTextStyle)
    val spanEnd = start + text.length
    val (safeStart, safeEnd) = spannable.getSafeSpanBoundaries(start, spanEnd)
    spannable.setSpan(span, safeStart, safeEnd, Spanned.SPAN_EXCLUSIVE_EXCLUSIVE)

    editorView.selection.validateStyles()
  }
}
