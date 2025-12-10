package com.swmansion.enriched.spans

import com.swmansion.enriched.styles.HtmlStyle

data class BaseSpanConfig(val clazz: Class<*>)
data class ParagraphSpanConfig(val clazz: Class<*>, val isContinuous: Boolean)
data class ListSpanConfig(val clazz: Class<*>, val shortcut: String)

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
  const val H4 = "h4"
  const val H5 = "h5"
  const val H6 = "h6"
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
    H4 to ParagraphSpanConfig(EnrichedH4Span::class.java, false),
    H5 to ParagraphSpanConfig(EnrichedH5Span::class.java, false),
    H6 to ParagraphSpanConfig(EnrichedH6Span::class.java, false),
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

  fun getMergingConfigForStyle(style: String, htmlStyle: HtmlStyle): StylesMergingConfig? {
    return when (style) {
      BOLD -> {
        val blockingStyles = mutableListOf(CODE_BLOCK)
        if (htmlStyle.h1Bold) blockingStyles.add(H1)
        if (htmlStyle.h2Bold) blockingStyles.add(H2)
        if (htmlStyle.h3Bold) blockingStyles.add(H3)
        if (htmlStyle.h4Bold) blockingStyles.add(H4)
        if (htmlStyle.h5Bold) blockingStyles.add(H5)
        if (htmlStyle.h6Bold) blockingStyles.add(H6)
        StylesMergingConfig(blockingStyles = blockingStyles.toTypedArray())
      }
      ITALIC -> StylesMergingConfig(
        blockingStyles = arrayOf(CODE_BLOCK)
      )
      UNDERLINE -> StylesMergingConfig(
        blockingStyles = arrayOf(CODE_BLOCK)
      )
      STRIKETHROUGH -> StylesMergingConfig(
        blockingStyles = arrayOf(CODE_BLOCK)
      )
      INLINE_CODE -> StylesMergingConfig(
        conflictingStyles = arrayOf(MENTION, LINK),
        blockingStyles = arrayOf(CODE_BLOCK)
      )
      H1 -> {
        val conflictingStyles = mutableListOf(H2, H3, H4, H5, H6, ORDERED_LIST, UNORDERED_LIST, BLOCK_QUOTE, CODE_BLOCK)
        if (htmlStyle.h1Bold) conflictingStyles.add(BOLD)
        StylesMergingConfig(conflictingStyles = conflictingStyles.toTypedArray())
      }
      H2 -> {
        val conflictingStyles = mutableListOf(H1, H3, H4, H5, H6, ORDERED_LIST, UNORDERED_LIST, BLOCK_QUOTE, CODE_BLOCK)
        if (htmlStyle.h2Bold) conflictingStyles.add(BOLD)
        StylesMergingConfig(conflictingStyles = conflictingStyles.toTypedArray())
      }
      H3 -> {
        val conflictingStyles = mutableListOf(H1, H2, H4, H5, H6, ORDERED_LIST, UNORDERED_LIST, BLOCK_QUOTE, CODE_BLOCK)
        if (htmlStyle.h3Bold) conflictingStyles.add(BOLD)
        StylesMergingConfig(conflictingStyles = conflictingStyles.toTypedArray())
      }
      H4 -> {
        val conflictingStyles = mutableListOf(H1, H2, H3, H5, H6, ORDERED_LIST, UNORDERED_LIST, BLOCK_QUOTE, CODE_BLOCK)
        if (htmlStyle.h4Bold) conflictingStyles.add(BOLD)
        StylesMergingConfig(conflictingStyles = conflictingStyles.toTypedArray())
      }
      H5 -> {
        val conflictingStyles = mutableListOf(H1, H2, H3, H4, H6, ORDERED_LIST, UNORDERED_LIST, BLOCK_QUOTE, CODE_BLOCK)
        if (htmlStyle.h5Bold) conflictingStyles.add(BOLD)
        StylesMergingConfig(conflictingStyles = conflictingStyles.toTypedArray())
      }
      H6 -> {
        val conflictingStyles = mutableListOf(H1, H2, H3, H4, H5, ORDERED_LIST, UNORDERED_LIST, BLOCK_QUOTE, CODE_BLOCK)
        if (htmlStyle.h6Bold) conflictingStyles.add(BOLD)
        StylesMergingConfig(conflictingStyles = conflictingStyles.toTypedArray())
      }
      BLOCK_QUOTE -> StylesMergingConfig(
        conflictingStyles = arrayOf(H1, H2, H3, H4, H5, H6, CODE_BLOCK, ORDERED_LIST, UNORDERED_LIST)
      )
      CODE_BLOCK -> StylesMergingConfig(
        conflictingStyles = arrayOf(H1, H2, H3, H4, H5, H6, BOLD, ITALIC, UNDERLINE, STRIKETHROUGH, UNORDERED_LIST, ORDERED_LIST, BLOCK_QUOTE, INLINE_CODE)
      )
      UNORDERED_LIST -> StylesMergingConfig(
        conflictingStyles = arrayOf(H1, H2, H3, H4, H5, H6, ORDERED_LIST, CODE_BLOCK, BLOCK_QUOTE)
      )
      ORDERED_LIST -> StylesMergingConfig(
        conflictingStyles = arrayOf(H1, H2, H3, H4, H5, H6, UNORDERED_LIST, CODE_BLOCK, BLOCK_QUOTE),
      )
      LINK -> StylesMergingConfig(
        blockingStyles = arrayOf(INLINE_CODE, CODE_BLOCK, MENTION)
      )
      IMAGE -> StylesMergingConfig()
      MENTION -> StylesMergingConfig(
        blockingStyles = arrayOf(INLINE_CODE, CODE_BLOCK, LINK)
      )
      else -> null
    }
  }

  fun isTypeContinuous(type: Class<*>): Boolean {
    return paragraphSpans.values.find { it.clazz == type }?.isContinuous == true
  }
}
