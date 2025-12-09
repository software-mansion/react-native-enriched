package com.swmansion.enriched.watchers

import android.text.SpanWatcher
import android.text.Spannable
import android.text.style.ParagraphStyle
import com.facebook.react.bridge.ReactContext
import com.facebook.react.uimanager.UIManagerHelper
import com.swmansion.enriched.EnrichedTextInputView
import com.swmansion.enriched.events.OnChangeHtmlEvent
import com.swmansion.enriched.spans.EnrichedOrderedListSpan
import com.swmansion.enriched.spans.interfaces.EnrichedHeadingSpan
import com.swmansion.enriched.spans.interfaces.EnrichedSpan
import com.swmansion.enriched.utils.EnrichedParser
import com.swmansion.enriched.utils.getSafeSpanBoundaries

class EnrichedSpanWatcher(private val view: EnrichedTextInputView) : SpanWatcher {
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
    if (what is EnrichedOrderedListSpan) {
      view.listStyles?.updateOrderedListIndexes(text, end)
    }
  }

  // After adding/removing heading span, we have to manually set empty paragraph span to the following text
  // This allows us to update the layout (as it's not updated automatically - looks like an Android issue)
  private fun updateNextLineLayout(what: Any, text: Spannable, end: Int) {
    class EmptySpan : ParagraphStyle {}

    if (what is EnrichedHeadingSpan) {
      val finalStart = (end + 1)
      val finalEnd = text.length
      val (safeStart, safeEnd) = text.getSafeSpanBoundaries(finalStart, finalEnd)
      text.setSpan(EmptySpan(), safeStart, safeEnd, Spannable.SPAN_EXCLUSIVE_EXCLUSIVE)
    }
  }

  fun emitEvent(s: Spannable, what: Any?) {
    // Do not parse spannable and emit event if onChangeHtml is not provided
    if (!view.shouldEmitHtml) return

    // Emit event only if we change one of ours spans
    if (what != null && what !is EnrichedSpan) return

    val html = EnrichedParser.toHtml(s)
    if (html == previousHtml) return

    previousHtml = html
    val context = view.context as ReactContext
    val surfaceId = UIManagerHelper.getSurfaceId(context)
    val dispatcher = UIManagerHelper.getEventDispatcherForReactTag(context, view.id)
    dispatcher?.dispatchEvent(OnChangeHtmlEvent(
      surfaceId,
      view.id,
      html,
      view.experimentalSynchronousEvents,
    ))
  }
}
