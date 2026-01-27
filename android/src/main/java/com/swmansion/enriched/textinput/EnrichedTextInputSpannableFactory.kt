package com.swmansion.enriched.textinput

import com.swmansion.enriched.common.parser.EnrichedSpanFactory
import com.swmansion.enriched.common.spans.EnrichedCheckboxListSpan
import com.swmansion.enriched.common.spans.EnrichedImageSpan
import com.swmansion.enriched.textinput.spans.EnrichedInputBlockQuoteSpan
import com.swmansion.enriched.textinput.spans.EnrichedInputBoldSpan
import com.swmansion.enriched.textinput.spans.EnrichedInputCheckboxListSpan
import com.swmansion.enriched.textinput.spans.EnrichedInputCodeBlockSpan
import com.swmansion.enriched.textinput.spans.EnrichedInputH1Span
import com.swmansion.enriched.textinput.spans.EnrichedInputH2Span
import com.swmansion.enriched.textinput.spans.EnrichedInputH3Span
import com.swmansion.enriched.textinput.spans.EnrichedInputH4Span
import com.swmansion.enriched.textinput.spans.EnrichedInputH5Span
import com.swmansion.enriched.textinput.spans.EnrichedInputH6Span
import com.swmansion.enriched.textinput.spans.EnrichedInputImageSpan
import com.swmansion.enriched.textinput.spans.EnrichedInputInlineCodeSpan
import com.swmansion.enriched.textinput.spans.EnrichedInputItalicSpan
import com.swmansion.enriched.textinput.spans.EnrichedInputLinkSpan
import com.swmansion.enriched.textinput.spans.EnrichedInputMentionSpan
import com.swmansion.enriched.textinput.spans.EnrichedInputOrderedListSpan
import com.swmansion.enriched.textinput.spans.EnrichedInputStrikeThroughSpan
import com.swmansion.enriched.textinput.spans.EnrichedInputUnderlineSpan
import com.swmansion.enriched.textinput.spans.EnrichedInputUnorderedListSpan
import com.swmansion.enriched.textinput.styles.HtmlStyle

class EnrichedTextInputSpannableFactory : EnrichedSpanFactory<HtmlStyle> {
  override fun createBoldSpan(style: HtmlStyle) = EnrichedInputBoldSpan(style)

  override fun createItalicSpan(style: HtmlStyle) = EnrichedInputItalicSpan(style)

  override fun createUnderlineSpan(style: HtmlStyle) = EnrichedInputUnderlineSpan(style)

  override fun createStrikeThroughSpan(style: HtmlStyle) = EnrichedInputStrikeThroughSpan(style)

  override fun createInlineCodeSpan(style: HtmlStyle) = EnrichedInputInlineCodeSpan(style)

  override fun createLinkSpan(
    url: String,
    style: HtmlStyle,
  ) = EnrichedInputLinkSpan(url, style)

  override fun createMentionSpan(
    text: String,
    indicator: String,
    attributes: Map<String, String>,
    style: HtmlStyle,
  ) = EnrichedInputMentionSpan(text, indicator, attributes, style)

  override fun createImageSpan(
    source: String,
    width: Int,
    height: Int,
  ): EnrichedImageSpan = EnrichedInputImageSpan.createEnrichedImageSpan(source, width, height)

  override fun createH1Span(style: HtmlStyle) = EnrichedInputH1Span(style)

  override fun createH2Span(style: HtmlStyle) = EnrichedInputH2Span(style)

  override fun createH3Span(style: HtmlStyle) = EnrichedInputH3Span(style)

  override fun createH4Span(style: HtmlStyle) = EnrichedInputH4Span(style)

  override fun createH5Span(style: HtmlStyle) = EnrichedInputH5Span(style)

  override fun createH6Span(style: HtmlStyle) = EnrichedInputH6Span(style)

  override fun createOrderedListSpan(
    index: Int,
    style: HtmlStyle,
  ) = EnrichedInputOrderedListSpan(index, style)

  override fun createUnorderedListSpan(style: HtmlStyle) = EnrichedInputUnorderedListSpan(style)

  override fun createCheckboxListSpan(
    isChecked: Boolean,
    style: HtmlStyle,
  ) = EnrichedInputCheckboxListSpan(isChecked, style)

  override fun createBlockQuoteSpan(style: HtmlStyle) = EnrichedInputBlockQuoteSpan(style)

  override fun createCodeBlockSpan(style: HtmlStyle) = EnrichedInputCodeBlockSpan(style)
}
