package com.swmansion.enriched.text

import com.swmansion.enriched.common.parser.EnrichedSpanFactory
import com.swmansion.enriched.text.spans.EnrichedTextBlockQuoteSpan
import com.swmansion.enriched.text.spans.EnrichedTextBoldSpan
import com.swmansion.enriched.text.spans.EnrichedTextCodeBlockSpan
import com.swmansion.enriched.text.spans.EnrichedTextH1Span
import com.swmansion.enriched.text.spans.EnrichedTextH2Span
import com.swmansion.enriched.text.spans.EnrichedTextH3Span
import com.swmansion.enriched.text.spans.EnrichedTextH4Span
import com.swmansion.enriched.text.spans.EnrichedTextH5Span
import com.swmansion.enriched.text.spans.EnrichedTextH6Span
import com.swmansion.enriched.text.spans.EnrichedTextImageSpan
import com.swmansion.enriched.text.spans.EnrichedTextInlineCodeSpan
import com.swmansion.enriched.text.spans.EnrichedTextItalicSpan
import com.swmansion.enriched.text.spans.EnrichedTextLinkSpan
import com.swmansion.enriched.text.spans.EnrichedTextMentionSpan
import com.swmansion.enriched.text.spans.EnrichedTextOrderedListSpan
import com.swmansion.enriched.text.spans.EnrichedTextStrikeThroughSpan
import com.swmansion.enriched.text.spans.EnrichedTextUnderlineSpan
import com.swmansion.enriched.text.spans.EnrichedTextUnorderedListSpan

class EnrichedTextSpanFactory : EnrichedSpanFactory<EnrichedTextStyle> {
  override fun createBoldSpan(style: EnrichedTextStyle) = EnrichedTextBoldSpan(style)

  override fun createItalicSpan(style: EnrichedTextStyle) = EnrichedTextItalicSpan(style)

  override fun createUnderlineSpan(style: EnrichedTextStyle) = EnrichedTextUnderlineSpan(style)

  override fun createStrikeThroughSpan(style: EnrichedTextStyle) = EnrichedTextStrikeThroughSpan(style)

  override fun createInlineCodeSpan(style: EnrichedTextStyle) = EnrichedTextInlineCodeSpan(style)

  override fun createLinkSpan(
    url: String,
    style: EnrichedTextStyle,
  ) = EnrichedTextLinkSpan(url, style)

  override fun createMentionSpan(
    text: String,
    indicator: String,
    attributes: Map<String, String>,
    style: EnrichedTextStyle,
  ) = EnrichedTextMentionSpan(text, indicator, attributes, style)

  override fun createImageSpan(
    source: String,
    width: Int,
    height: Int,
  ) = EnrichedTextImageSpan.createEnrichedImageSpan(source, width, height)

  override fun createH1Span(style: EnrichedTextStyle) = EnrichedTextH1Span(style)

  override fun createH2Span(style: EnrichedTextStyle) = EnrichedTextH2Span(style)

  override fun createH3Span(style: EnrichedTextStyle) = EnrichedTextH3Span(style)

  override fun createH4Span(style: EnrichedTextStyle) = EnrichedTextH4Span(style)

  override fun createH5Span(style: EnrichedTextStyle) = EnrichedTextH5Span(style)

  override fun createH6Span(style: EnrichedTextStyle) = EnrichedTextH6Span(style)

  override fun createOrderedListSpan(
    index: Int,
    style: EnrichedTextStyle,
  ) = EnrichedTextOrderedListSpan(index, style)

  override fun createUnorderedListSpan(style: EnrichedTextStyle) = EnrichedTextUnorderedListSpan(style)

  override fun createBlockQuoteSpan(style: EnrichedTextStyle) = EnrichedTextBlockQuoteSpan(style)

  override fun createCodeBlockSpan(style: EnrichedTextStyle) = EnrichedTextCodeBlockSpan(style)
}
