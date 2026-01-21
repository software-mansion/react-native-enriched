package com.swmansion.enriched.textinput.utils

import android.text.Editable
import android.text.Spannable
import android.text.SpannableStringBuilder
import com.swmansion.enriched.textinput.watchers.EnrichedSpanWatcher

class EnrichedEditableFactory(
  private val watcher: EnrichedSpanWatcher,
) : Editable.Factory() {
  override fun newEditable(source: CharSequence): Editable {
    val s = source as? SpannableStringBuilder ?: SpannableStringBuilder(source)
    s.removeSpan(watcher)
    s.setSpan(watcher, 0, s.length, Spannable.SPAN_INCLUSIVE_INCLUSIVE)
    return s
  }
}
