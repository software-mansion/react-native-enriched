package com.swmansion.reactnativerichtexteditor.watchers

import android.text.SpanWatcher
import android.text.Spannable
import android.text.style.ParagraphStyle
import com.facebook.react.bridge.ReactContext
import com.facebook.react.uimanager.UIManagerHelper
import com.swmansion.reactnativerichtexteditor.ReactNativeRichTextEditorView
import com.swmansion.reactnativerichtexteditor.events.OnChangeHtmlEvent
import com.swmansion.reactnativerichtexteditor.spans.EditorOrderedListSpan
import com.swmansion.reactnativerichtexteditor.spans.interfaces.EditorHeadingSpan
import com.swmansion.reactnativerichtexteditor.spans.interfaces.EditorSpan
import com.swmansion.reactnativerichtexteditor.utils.EditorParser
import com.swmansion.reactnativerichtexteditor.utils.getSafeSpanBoundaries

class EditorSpanWatcher(private val editorView: ReactNativeRichTextEditorView) : SpanWatcher {
  private var previousHtml: String? = null

  override fun onSpanAdded(text: Spannable, what: Any, start: Int, end: Int) {
    updateNextLineLayout(what, text, end)
    updateUnorderedListSpans(what, text, end)
    emitEvent(text, what)
  }

  override fun onSpanRemoved(text: Spannable, what: Any, start: Int, end: Int) {
    updateNextLineLayout(what, text, end)
    updateUnorderedListSpans(what, text, end)
    emitEvent(text, what)
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
      val finalStart = (end + 1)
      val finalEnd = text.length
      val (safeStart, safeEnd) = text.getSafeSpanBoundaries(finalStart, finalEnd)
      text.setSpan(EmptySpan(), safeStart, safeEnd, Spannable.SPAN_EXCLUSIVE_EXCLUSIVE)
    }
  }

  fun emitEvent(s: Spannable, what: Any?) {
    // Emit event only if we change one of ours spans
    if (what != null && what !is EditorSpan) return;

    val html = EditorParser.toHtml(s, EditorParser.TO_HTML_PARAGRAPH_LINES_INDIVIDUAL)
    if (html == previousHtml) return;

    previousHtml = html
    editorView.layoutManager.invalidateLayout(editorView.text)
    val context = editorView.context as ReactContext
    val surfaceId = UIManagerHelper.getSurfaceId(context)
    val dispatcher = UIManagerHelper.getEventDispatcherForReactTag(context, editorView.id)
    dispatcher?.dispatchEvent(OnChangeHtmlEvent(surfaceId, editorView.id, html))
  }
}
