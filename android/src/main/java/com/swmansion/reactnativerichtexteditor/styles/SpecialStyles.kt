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
import java.io.File

class SpecialStyles(private val editorView: ReactNativeRichTextEditorView) {
  private var mentionStart: Int? = null

  fun setLinkSpan(text: String, url: String) {
    val linkHandler = editorView.linkHandler ?: return
    val selection = editorView.selection ?: return

    val spannable = editorView.text as SpannableStringBuilder
    var (selectionStart, selectionEnd) = selection.getInlineSelection()

    val spans = spannable.getSpans(selectionStart, selectionEnd, EditorLinkSpan::class.java)
    for (span in spans) {
      spannable.removeSpan(span)
    }

    if (selectionStart == selectionEnd) {
      spannable.insert(selectionStart, text)
    } else {
      spannable.replace(selectionStart, selectionEnd, text)
    }

    val end = selectionStart + text.length
    val span = EditorLinkSpan(url, linkHandler)
    spannable.setSpan(span, selectionStart, end, Spanned.SPAN_EXCLUSIVE_EXCLUSIVE)
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
    val linkHandler = editorView.linkHandler ?: return
    val spannable = editorView.text as Spannable
    val (word, start, end) = result

    // TODO: Consider using more reliable regex, this one matches almost anything
    val urlPattern = android.util.Patterns.WEB_URL.matcher(word)

    val spans = spannable.getSpans(start, end, EditorLinkSpan::class.java)
    for (span in spans) {
      spannable.removeSpan(span)
    }

    if (urlPattern.matches()) {
      val span = EditorLinkSpan(word, linkHandler)
      spannable.setSpan(span, start, end, Spanned.SPAN_EXCLUSIVE_EXCLUSIVE)
    }
  }

  private fun afterTextChangedMentions(result: Triple<String, Int, Int>) {
    val mentionHandler = editorView.mentionHandler ?: return
    val spannable = editorView.text as Spannable
    val (word, start, end) = result

    val mentionPattern = Regex("^@\\w+")
    val spans = spannable.getSpans(start, end, EditorMentionSpan::class.java)
    for (span in spans) {
      spannable.removeSpan(span)
    }

    if (mentionPattern.matches(word)) {
      // Mention updated
      mentionHandler.onMention(word.replace("@", ""))
    } else if (word.startsWith("@")) {
      // Mention started
      mentionStart = start
      mentionHandler.onMention("")
    } else {
      // Mention ended
      mentionHandler.onMention(null)
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
    val span = EditorImageSpan(editorView.context, uri)
    spannable.setSpan(span, start, end, Spannable.SPAN_EXCLUSIVE_EXCLUSIVE)
  }

  fun startMention() {
    val selection = editorView.selection ?: return

    val spannable = editorView.text as SpannableStringBuilder
    var (start, end) = selection.getInlineSelection()

    if (start == end) {
      spannable.insert(start, "@")
    } else {
      spannable.replace(start, end, "@")
    }
  }

  fun setMentionSpan(text: String, value: String) {
    val mentionHandler = editorView.mentionHandler ?: return
    val selection = editorView.selection ?: return

    val spannable = editorView.text as SpannableStringBuilder
    var (selectionStart, selectionEnd) = selection.getInlineSelection()
    val spans = spannable.getSpans(selectionStart, selectionEnd, EditorMentionSpan::class.java)

    for (span in spans) {
      spannable.removeSpan(span)
    }

    var start = mentionStart ?: return
    spannable.replace(start + 1, selectionEnd, text)

    val span = EditorMentionSpan(value, text, mentionHandler)
    // start + text + 1 (because we need to account for the "@" character)
    val spanEnd = start + text.length + 1
    spannable.setSpan(span, start, spanEnd, Spanned.SPAN_EXCLUSIVE_EXCLUSIVE)
  }
}
