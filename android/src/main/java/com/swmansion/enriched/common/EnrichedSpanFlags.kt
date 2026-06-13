package com.swmansion.enriched.common

import android.text.Spannable
import com.swmansion.enriched.common.spans.interfaces.EnrichedInlineSpan
import com.swmansion.enriched.common.spans.interfaces.EnrichedSpan

object EnrichedSpanFlags {
  private const val PARAGRAPH_SPAN_PRIORITY = 2
  private const val INLINE_SPAN_PRIORITY = 1

  @JvmField
  val paragraphSpanFlags: Int = applyPriority(Spannable.SPAN_EXCLUSIVE_EXCLUSIVE, PARAGRAPH_SPAN_PRIORITY)

  @JvmField
  val inlineSpanFlags: Int = applyPriority(Spannable.SPAN_EXCLUSIVE_EXCLUSIVE, INLINE_SPAN_PRIORITY)

  fun forSpan(
    span: EnrichedSpan,
    baseFlags: Int,
  ): Int {
    val isInlineSpan = span is EnrichedInlineSpan
    val priority = if (isInlineSpan) INLINE_SPAN_PRIORITY else PARAGRAPH_SPAN_PRIORITY
    return applyPriority(baseFlags, priority)
  }

  private fun applyPriority(
    flags: Int,
    priority: Int,
  ): Int {
    // Cleaning up priority bits
    val cleared = flags and Spannable.SPAN_PRIORITY.inv()
    // Injecting priority bits
    return cleared or ((priority shl Spannable.SPAN_PRIORITY_SHIFT) and Spannable.SPAN_PRIORITY)
  }
}
