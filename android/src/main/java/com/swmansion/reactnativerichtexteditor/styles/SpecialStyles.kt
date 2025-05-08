package com.swmansion.reactnativerichtexteditor.styles

import android.text.Editable
import android.text.Spannable
import android.text.SpannableStringBuilder
import android.text.Spanned
import com.swmansion.reactnativerichtexteditor.ReactNativeRichTextEditorView
import com.swmansion.reactnativerichtexteditor.spans.EditorLinkSpan

class SpecialStyles(private val editorView: ReactNativeRichTextEditorView) {
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
}
