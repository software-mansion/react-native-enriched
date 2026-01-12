package com.swmansion.enriched.spans

import android.graphics.Canvas
import android.graphics.Paint
import android.text.Layout
import android.text.Spanned
import android.text.TextPaint
import android.text.style.LeadingMarginSpan
import android.text.style.MetricAffectingSpan
import androidx.core.graphics.withTranslation
import com.swmansion.enriched.spans.interfaces.EnrichedParagraphSpan
import com.swmansion.enriched.styles.HtmlStyle
import com.swmansion.enriched.utils.ResourceManager

class EnrichedCheckboxListSpan(
  var isChecked: Boolean,
  private val htmlStyle: HtmlStyle,
) : MetricAffectingSpan(),
  LeadingMarginSpan,
  EnrichedParagraphSpan {
  override val dependsOnHtmlStyle: Boolean = true

  // TODO: use custom drawables. Consider customizing color of them
  private val checkedDrawable = ResourceManager.getDrawableResource(android.R.drawable.checkbox_on_background)
  private val uncheckedDrawable = ResourceManager.getDrawableResource(android.R.drawable.checkbox_off_background)

  init {
    checkedDrawable.setBounds(0, 0, htmlStyle.ulCheckboxBoxSize, htmlStyle.ulCheckboxBoxSize)
    uncheckedDrawable.setBounds(0, 0, htmlStyle.ulCheckboxBoxSize, htmlStyle.ulCheckboxBoxSize)
  }

  override fun updateMeasureState(p0: TextPaint) {
    // Do nothing, but inform layout that this span affects text metrics
  }

  override fun updateDrawState(p0: TextPaint?) {
    // Do nothing, but inform layout that this span affects text metrics
  }

  override fun getLeadingMargin(first: Boolean): Int =
    htmlStyle.ulCheckboxBoxSize + htmlStyle.ulCheckboxMarginLeft + htmlStyle.ulCheckboxGapWidth

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
      val drawable = if (isChecked) checkedDrawable else uncheckedDrawable

      val fontMetrics = paint.fontMetrics
      val lineCenter = baseline + (fontMetrics.ascent + fontMetrics.descent) / 2f
      val drawableTop = lineCenter - (htmlStyle.ulCheckboxBoxSize / 2f)

      canvas.withTranslation(x.toFloat() + htmlStyle.ulCheckboxMarginLeft, drawableTop) {
        drawable.draw(this)
      }
    }
  }

  override fun rebuildWithStyle(htmlStyle: HtmlStyle): EnrichedCheckboxListSpan = EnrichedCheckboxListSpan(isChecked, htmlStyle)
}
