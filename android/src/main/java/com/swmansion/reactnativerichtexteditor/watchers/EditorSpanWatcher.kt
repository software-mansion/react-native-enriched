package com.swmansion.reactnativerichtexteditor.watchers

import android.text.SpanWatcher
import android.text.Spannable
import android.text.style.ParagraphStyle
import com.swmansion.reactnativerichtexteditor.ReactNativeRichTextEditorView
import com.swmansion.reactnativerichtexteditor.spans.EditorOrderedListSpan
import com.swmansion.reactnativerichtexteditor.spans.interfaces.EditorHeadingSpan

class EditorSpanWatcher(private val editorView: ReactNativeRichTextEditorView) : SpanWatcher {
  override fun onSpanAdded(text: Spannable, what: Any, start: Int, end: Int) {
    updateNextLineLayout(what, text, end)
    updateUnorderedListSpans(what, text, end)
  }

  override fun onSpanRemoved(text: Spannable, what: Any, start: Int, end: Int) {
    updateNextLineLayout(what, text, end)
    updateUnorderedListSpans(what, text, end)
  }

  override fun onSpanChanged(text: Spannable, what: Any, ostart: Int, oend: Int, nstart: Int, nend: Int) {
    // Do nothing for now
  }

  private fun updateUnorderedListSpans(what: Any, text: Spannable, end: Int) {
    if (what is EditorOrderedListSpan) {
      editorView.listStyles?.updateOrderedListIndexes(text, end)
    }
  }

  // After adding/removing heading span, we have to manually set empty paragraph span to the following text
  // This allows us to update the layout (as it's not updated automatically - looks like an Android issue)
  private fun updateNextLineLayout(what: Any, text: Spannable, end: Int) {
    class EmptySpan : ParagraphStyle {}

    if (what is EditorHeadingSpan) {
      val finalStart = (end + 1).coerceAtMost(text.length)
      val finalEnd = text.length
      text.setSpan(EmptySpan(), finalStart, finalEnd, Spannable.SPAN_EXCLUSIVE_EXCLUSIVE)
    }
  }
}
