package com.swmansion.enriched.common.spans

import android.text.Layout
import android.text.style.AlignmentSpan

open class EnrichedAlignmentSpan(
  val cssValue: String,
) : AlignmentSpan.Standard(cssValueToLayoutAlignment(cssValue)) {
  companion object {
    fun cssValueToLayoutAlignment(cssValue: String): Layout.Alignment =
      when (cssValue) {
        "center" -> Layout.Alignment.ALIGN_CENTER
        "right" -> Layout.Alignment.ALIGN_OPPOSITE
        else -> Layout.Alignment.ALIGN_NORMAL
      }
  }
}
