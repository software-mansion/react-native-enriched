package com.swmansion.enriched.text.spans

import android.view.View
import com.facebook.react.bridge.ReactContext
import com.facebook.react.uimanager.UIManagerHelper
import com.swmansion.enriched.common.spans.EnrichedLinkSpan
import com.swmansion.enriched.text.EnrichedTextStyle
import com.swmansion.enriched.text.events.OnLinkPress
import com.swmansion.enriched.text.spans.interfaces.EnrichedTextClickableSpan
import com.swmansion.enriched.text.spans.interfaces.EnrichedTextSpan

class EnrichedTextLinkSpan(
  private val url: String,
  enrichedStyle: EnrichedTextStyle,
) : EnrichedLinkSpan(url, enrichedStyle),
  EnrichedTextSpan,
  EnrichedTextClickableSpan {
  override val dependsOnHtmlStyle = true
  override var isPressed = false

  override fun rebuildWithStyle(style: EnrichedTextStyle) = EnrichedTextLinkSpan(url, style)

  override fun onClick(view: View) {
    val context = view.context as? ReactContext ?: return
    val surfaceId = UIManagerHelper.getSurfaceId(context)
    val dispatcher = UIManagerHelper.getEventDispatcherForReactTag(context, view.id)
    dispatcher?.dispatchEvent(
      OnLinkPress(
        surfaceId,
        view.id,
        url,
      ),
    )
  }
}
