package com.swmansion.enriched.text.spans.interfaces

import android.view.View

interface EnrichedTextClickableSpan {
  var isPressed: Boolean

  fun onClick(view: View)
}
