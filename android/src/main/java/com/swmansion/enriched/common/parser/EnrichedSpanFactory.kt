package com.swmansion.enriched.common.parser

import com.swmansion.enriched.common.spans.EnrichedBlockQuoteSpan
import com.swmansion.enriched.common.spans.EnrichedBoldSpan
import com.swmansion.enriched.common.spans.EnrichedCheckboxListSpan
import com.swmansion.enriched.common.spans.EnrichedCodeBlockSpan
import com.swmansion.enriched.common.spans.EnrichedH1Span
import com.swmansion.enriched.common.spans.EnrichedH2Span
import com.swmansion.enriched.common.spans.EnrichedH3Span
import com.swmansion.enriched.common.spans.EnrichedH4Span
import com.swmansion.enriched.common.spans.EnrichedH5Span
import com.swmansion.enriched.common.spans.EnrichedH6Span
import com.swmansion.enriched.common.spans.EnrichedImageSpan
import com.swmansion.enriched.common.spans.EnrichedInlineCodeSpan
import com.swmansion.enriched.common.spans.EnrichedItalicSpan
import com.swmansion.enriched.common.spans.EnrichedLinkSpan
import com.swmansion.enriched.common.spans.EnrichedMentionSpan
import com.swmansion.enriched.common.spans.EnrichedOrderedListSpan
import com.swmansion.enriched.common.spans.EnrichedStrikeThroughSpan
import com.swmansion.enriched.common.spans.EnrichedUnderlineSpan
import com.swmansion.enriched.common.spans.EnrichedUnorderedListSpan

interface EnrichedSpanFactory<T> {
  fun createBoldSpan(style: T): EnrichedBoldSpan

  fun createItalicSpan(style: T): EnrichedItalicSpan

  fun createUnderlineSpan(style: T): EnrichedUnderlineSpan

  fun createStrikeThroughSpan(style: T): EnrichedStrikeThroughSpan

  fun createInlineCodeSpan(style: T): EnrichedInlineCodeSpan

  fun createLinkSpan(
    url: String,
    style: T,
  ): EnrichedLinkSpan

  fun createMentionSpan(
    text: String,
    indicator: String,
    attributes: Map<String, String>,
    style: T,
  ): EnrichedMentionSpan

  fun createImageSpan(
    source: String,
    width: Int,
    height: Int,
  ): EnrichedImageSpan

  fun createH1Span(style: T): EnrichedH1Span

  fun createH2Span(style: T): EnrichedH2Span

  fun createH3Span(style: T): EnrichedH3Span

  fun createH4Span(style: T): EnrichedH4Span

  fun createH5Span(style: T): EnrichedH5Span

  fun createH6Span(style: T): EnrichedH6Span

  fun createOrderedListSpan(
    index: Int,
    style: T,
  ): EnrichedOrderedListSpan

  fun createUnorderedListSpan(style: T): EnrichedUnorderedListSpan

  fun createCheckboxListSpan(
    isChecked: Boolean,
    style: T,
  ): EnrichedCheckboxListSpan

  fun createBlockQuoteSpan(style: T): EnrichedBlockQuoteSpan

  fun createCodeBlockSpan(style: T): EnrichedCodeBlockSpan
}
