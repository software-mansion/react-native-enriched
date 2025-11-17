package com.swmansion.enriched.spans

interface ISpanConfig {
  val clazz: Class<*>
}

data class BaseSpanConfig(override  val clazz: Class<*>): ISpanConfig
data class ParagraphSpanConfig(override  val clazz: Class<*>, val isContinuous: Boolean): ISpanConfig
data class ListSpanConfig(override val clazz: Class<*>, val shortcut: String) : ISpanConfig


data class StylesMergingConfig(
  // styles that should be removed when we apply specific style
  val conflictingStyles: Array<String> = emptyArray(),
  // styles that should block setting specific style
  val blockingStyles: Array<String> = emptyArray(),
)

object EnrichedSpans {
  // inline styles
  const val BOLD = "bold"
  const val ITALIC = "italic"
  const val UNDERLINE = "underline"
  const val STRIKETHROUGH = "strikethrough"
  const val INLINE_CODE = "inline_code"

  // paragraph styles
  const val H1 = "h1"
  const val H2 = "h2"
  const val H3 = "h3"
  const val BLOCK_QUOTE = "block_quote"
  const val CODE_BLOCK = "code_block"

  // list styles
  const val UNORDERED_LIST = "unordered_list"
  const val ORDERED_LIST = "ordered_list"

  // parametrized styles
  const val LINK = "link"
  const val IMAGE = "image"
  const val MENTION = "mention"

  val inlineSpans: Map<String, BaseSpanConfig> = mapOf(
    BOLD to BaseSpanConfig(EnrichedBoldSpan::class.java),
    ITALIC to BaseSpanConfig(EnrichedItalicSpan::class.java),
    UNDERLINE to BaseSpanConfig(EnrichedUnderlineSpan::class.java),
    STRIKETHROUGH to BaseSpanConfig(EnrichedStrikeThroughSpan::class.java),
    INLINE_CODE to BaseSpanConfig(EnrichedInlineCodeSpan::class.java),
  )

  val paragraphSpans: Map<String, ParagraphSpanConfig> = mapOf(
    H1 to ParagraphSpanConfig(EnrichedH1Span::class.java, false),
    H2 to ParagraphSpanConfig(EnrichedH2Span::class.java, false),
    H3 to ParagraphSpanConfig(EnrichedH3Span::class.java, false),
    BLOCK_QUOTE to ParagraphSpanConfig(EnrichedBlockQuoteSpan::class.java, true),
    CODE_BLOCK to ParagraphSpanConfig(EnrichedCodeBlockSpan::class.java, true),
  )

  val listSpans: Map<String, ListSpanConfig> = mapOf(
    UNORDERED_LIST to ListSpanConfig(EnrichedUnorderedListSpan::class.java, "- "),
    ORDERED_LIST to ListSpanConfig(EnrichedOrderedListSpan::class.java, "1. "),
  )

  val parametrizedStyles: Map<String, BaseSpanConfig> = mapOf(
    LINK to BaseSpanConfig(EnrichedLinkSpan::class.java),
    IMAGE to BaseSpanConfig(EnrichedImageSpan::class.java),
    MENTION to BaseSpanConfig(EnrichedMentionSpan::class.java),
  )

  val allSpans: Map<String, ISpanConfig> = inlineSpans + paragraphSpans + listSpans + parametrizedStyles
  val mergingConfig: Map<String, StylesMergingConfig> = mapOf(
    BOLD to StylesMergingConfig(
      blockingStyles = arrayOf(CODE_BLOCK)
    ),
    ITALIC to StylesMergingConfig(
      blockingStyles = arrayOf(CODE_BLOCK)
    ),
    UNDERLINE to StylesMergingConfig(
      blockingStyles = arrayOf(CODE_BLOCK)
    ),
    STRIKETHROUGH to StylesMergingConfig(
      blockingStyles = arrayOf(CODE_BLOCK)
    ),
    INLINE_CODE to StylesMergingConfig(
      conflictingStyles = arrayOf(MENTION, LINK),
      blockingStyles = arrayOf(CODE_BLOCK)
    ),
    H1 to StylesMergingConfig(
      conflictingStyles = arrayOf(H2, H3, ORDERED_LIST, UNORDERED_LIST, BLOCK_QUOTE, CODE_BLOCK),
    ),
    H2 to StylesMergingConfig(
      conflictingStyles = arrayOf(H1, H3, ORDERED_LIST, UNORDERED_LIST, BLOCK_QUOTE, CODE_BLOCK),
    ),
    H3 to StylesMergingConfig(
      conflictingStyles = arrayOf(H1, H2, ORDERED_LIST, UNORDERED_LIST, BLOCK_QUOTE, CODE_BLOCK),
    ),
    BLOCK_QUOTE to StylesMergingConfig(
      conflictingStyles = arrayOf(H1, H2, H3, CODE_BLOCK, ORDERED_LIST, UNORDERED_LIST),
    ),
    CODE_BLOCK to StylesMergingConfig(
      conflictingStyles = arrayOf(H1, H2, H3, BOLD, ITALIC, UNDERLINE, STRIKETHROUGH, UNORDERED_LIST, ORDERED_LIST, BLOCK_QUOTE, INLINE_CODE),
    ),
    UNORDERED_LIST to StylesMergingConfig(
      conflictingStyles = arrayOf(H1, H2, H3, ORDERED_LIST, CODE_BLOCK, BLOCK_QUOTE),
    ),
    ORDERED_LIST to StylesMergingConfig(
      conflictingStyles = arrayOf(H1, H2, H3, UNORDERED_LIST, CODE_BLOCK, BLOCK_QUOTE),
    ),
    LINK to StylesMergingConfig(
      blockingStyles = arrayOf(INLINE_CODE, CODE_BLOCK, MENTION)
    ),
    IMAGE to StylesMergingConfig(),
    MENTION to StylesMergingConfig(
      blockingStyles = arrayOf(INLINE_CODE, CODE_BLOCK, LINK)
    ),
  )
}
