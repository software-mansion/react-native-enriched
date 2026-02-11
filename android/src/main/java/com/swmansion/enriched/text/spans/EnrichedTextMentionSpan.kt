package com.swmansion.enriched.text.spans

import android.text.TextPaint
import android.view.View
import com.facebook.react.bridge.ReactContext
import com.facebook.react.uimanager.UIManagerHelper
import com.swmansion.enriched.common.EnrichedStyle
import com.swmansion.enriched.common.spans.EnrichedMentionSpan
import com.swmansion.enriched.text.EnrichedTextStyle
import com.swmansion.enriched.text.events.OnMentionPressEvent
import com.swmansion.enriched.text.spans.interfaces.EnrichedTextClickableSpan
import com.swmansion.enriched.text.spans.interfaces.EnrichedTextSpan

class EnrichedTextMentionSpan(
  private val text: String,
  private val indicator: String,
  private val attributes: Map<String, String>,
  private val enrichedStyle: EnrichedStyle,
) : EnrichedMentionSpan(text, indicator, attributes, enrichedStyle),
  EnrichedTextSpan,
  EnrichedTextClickableSpan {
  override val dependsOnHtmlStyle = true
  override var isPressed = false

  override fun rebuildWithStyle(style: EnrichedTextStyle) = EnrichedTextMentionSpan(text, indicator, attributes, style)

  override fun updateDrawState(textPaint: TextPaint) {
    super.updateDrawState(textPaint)

    val mentionsStyle = enrichedStyle.mentionsStyle[indicator] ?: return
    val color =
      if (isPressed && mentionsStyle.pressColor != null) {
        mentionsStyle.pressColor
      } else {
        mentionsStyle.color
      }

    val bgColor =
      if (isPressed && mentionsStyle.pressBackgroundColor != null) {
        mentionsStyle.pressBackgroundColor
      } else {
        mentionsStyle.backgroundColor
      }

    textPaint.color = color
    textPaint.bgColor = bgColor
  }

  override fun onClick(view: View) {
    val context = view.context as? ReactContext ?: return
    val surfaceId = UIManagerHelper.getSurfaceId(context)
    val dispatcher = UIManagerHelper.getEventDispatcherForReactTag(context, view.id)
    dispatcher?.dispatchEvent(
      OnMentionPressEvent(
        surfaceId,
        view.id,
        text,
        indicator,
        attributes,
      ),
    )
  }
}
