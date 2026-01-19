package com.swmansion.enriched.text.spans

import android.view.View
import com.facebook.react.bridge.ReactContext
import com.facebook.react.uimanager.UIManagerHelper
import com.swmansion.enriched.common.EnrichedStyle
import com.swmansion.enriched.common.spans.EnrichedMentionSpan
import com.swmansion.enriched.text.EnrichedTextStyle
import com.swmansion.enriched.text.events.OnMentionPress
import com.swmansion.enriched.text.spans.interfaces.EnrichedTextClickableSpan
import com.swmansion.enriched.text.spans.interfaces.EnrichedTextSpan

class EnrichedTextMentionSpan(
  private val text: String,
  private val indicator: String,
  private val attributes: Map<String, String>,
  enrichedStyle: EnrichedStyle,
) : EnrichedMentionSpan(text, indicator, attributes, enrichedStyle),
  EnrichedTextSpan,
  EnrichedTextClickableSpan {
  override val dependsOnHtmlStyle = true
  override var isPressed = false

  override fun rebuildWithStyle(style: EnrichedTextStyle) = EnrichedTextMentionSpan(text, indicator, attributes, style)

  override fun onClick(view: View) {
    val context = view.context as? ReactContext ?: return
    val surfaceId = UIManagerHelper.getSurfaceId(context)
    val dispatcher = UIManagerHelper.getEventDispatcherForReactTag(context, view.id)
    dispatcher?.dispatchEvent(
      OnMentionPress(
        surfaceId,
        view.id,
        text,
        indicator,
        attributes,
      ),
    )
  }
}
