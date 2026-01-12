package com.swmansion.enriched.spans

import android.graphics.Canvas
import android.graphics.Paint
import android.text.Layout
import android.text.Spanned
import android.text.TextPaint
import android.text.style.LeadingMarginSpan
import android.text.style.LineHeightSpan
import android.text.style.MetricAffectingSpan
import androidx.core.graphics.withTranslation
import com.swmansion.enriched.spans.interfaces.EnrichedParagraphSpan
import com.swmansion.enriched.styles.HtmlStyle
import com.swmansion.enriched.utils.CheckboxDrawable

class EnrichedCheckboxListSpan(
  var isChecked: Boolean,
  private val htmlStyle: HtmlStyle,
) : MetricAffectingSpan(),
  LineHeightSpan,
  LeadingMarginSpan,
  EnrichedParagraphSpan {
  override val dependsOnHtmlStyle: Boolean = true

  private val checkboxDrawable =
    CheckboxDrawable(htmlStyle.ulCheckboxBoxSize, htmlStyle.ulCheckboxBoxColor, isChecked).apply {
      setBounds(0, 0, htmlStyle.ulCheckboxBoxSize, htmlStyle.ulCheckboxBoxSize)
    }

  override fun updateMeasureState(tp: TextPaint) {
    // Do nothing, but inform layout that this span affects text metrics
  }

  override fun updateDrawState(tp: TextPaint) {
    // Do nothing, but inform layout that this span affects text metrics
  }

  // Include checkbox size in text measurements to avoid clipping
  override fun chooseHeight(
    text: CharSequence,
    start: Int,
    end: Int,
    spanstartv: Int,
    v: Int,
    fm: Paint.FontMetricsInt,
  ) {
    val checkboxSize = htmlStyle.ulCheckboxBoxSize
    val currentLineHeight = fm.descent - fm.ascent

    if (checkboxSize > currentLineHeight) {
      val extraSpace = checkboxSize - currentLineHeight
      val halfExtra = extraSpace / 2

      fm.ascent -= halfExtra
      fm.descent += (extraSpace - halfExtra)

      fm.top -= halfExtra
      fm.bottom += (extraSpace - halfExtra)
    }
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
      checkboxDrawable.update(isChecked)

      val lineCenter = (top + bottom) / 2f
      val drawableTop = lineCenter - (htmlStyle.ulCheckboxBoxSize / 2f)

      canvas.withTranslation(x.toFloat() + htmlStyle.ulCheckboxMarginLeft, drawableTop) {
        checkboxDrawable.draw(this)
      }
    }
  }

  override fun rebuildWithStyle(htmlStyle: HtmlStyle): EnrichedCheckboxListSpan = EnrichedCheckboxListSpan(isChecked, htmlStyle)
}
