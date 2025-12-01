package com.swmansion.enriched.utils

import android.text.style.MetricAffectingSpan

class ForceRedrawSpan:  MetricAffectingSpan() {
  override fun updateMeasureState(p: android.text.TextPaint) {
    // Do nothing, we don't actually want to change how it looks
  }
  override fun updateDrawState(tp: android.text.TextPaint?) {
    // Do nothing
  }
}


