package com.swmansion.enriched.common.spans

import android.graphics.Canvas
import android.graphics.Paint
import android.text.Layout
import android.text.Spanned
import android.text.TextPaint
import android.text.style.LeadingMarginSpan
import android.text.style.MetricAffectingSpan
import com.swmansion.enriched.common.spans.interfaces.EnrichedParagraphSpan
import com.swmansion.enriched.textinput.styles.HtmlStyle

// https://android.googlesource.com/platform/frameworks/base/+/refs/heads/main/core/java/android/text/style/BulletSpan.java
class EnrichedUnorderedListSpan(
  private val htmlStyle: HtmlStyle,
) : MetricAffectingSpan(),
  LeadingMarginSpan,
  EnrichedParagraphSpan {
  override val dependsOnHtmlStyle: Boolean = true

  override fun updateMeasureState(p0: TextPaint) {
    // Do nothing, but inform layout that this span affects text metrics
  }

  override fun updateDrawState(p0: TextPaint?) {
    // Do nothing, but inform layout that this span affects text metrics
  }

  override fun getLeadingMargin(p0: Boolean): Int = htmlStyle.ulBulletSize + htmlStyle.ulGapWidth + htmlStyle.ulMarginLeft

  override fun drawLeadingMargin(
    canvas: Canvas,
    paint: Paint,
    x: Int,
    dir: Int,
    top: Int,
    baseline: Int,
    bottom: Int,
    text: CharSequence,
    start: Int,
    end: Int,
    first: Boolean,
    layout: Layout?,
  ) {
    val spannedText = text as Spanned

    if (spannedText.getSpanStart(this) == start) {
      val style = paint.style
      val oldColor = paint.color
      paint.color = htmlStyle.ulBulletColor
      paint.style = Paint.Style.FILL

      val bulletRadius = htmlStyle.ulBulletSize / 2f
      val yPosition = (top + bottom) / 2f
      val xPosition = x + dir * bulletRadius + htmlStyle.ulMarginLeft

      canvas.drawCircle(xPosition, yPosition, bulletRadius, paint)

      paint.color = oldColor
      paint.style = style
    }
  }

  override fun rebuildWithStyle(htmlStyle: HtmlStyle): EnrichedUnorderedListSpan = EnrichedUnorderedListSpan(htmlStyle)
}
