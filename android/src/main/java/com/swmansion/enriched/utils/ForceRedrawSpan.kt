package com.swmansion.enriched.utils

import android.text.TextPaint
import android.text.style.MetricAffectingSpan

class ForceRedrawSpan:  MetricAffectingSpan() {
  override fun updateMeasureState(tp: TextPaint) {
    // Do nothing, we don't actually want to change how it looks
  }
  override fun updateDrawState(tp: TextPaint?) {
    // Do nothing
  }
}


