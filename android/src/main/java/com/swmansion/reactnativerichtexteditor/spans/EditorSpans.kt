package com.swmansion.reactnativerichtexteditor.spans

data class BaseSpanConfig(val clazz: Class<*>)
data class ParagraphSpanConfig(val clazz: Class<*>, val isContinuous: Boolean)
data class ListSpanConfig(val clazz: Class<*>, val shortcut: String)

data class StylesMergingConfig(
  // styles that should be removed when we apply specific style
  val conflictingStyles: Array<String> = emptyArray(),
  // styles that should block setting specific style
  val blockingStyles: Array<String> = emptyArray(),
)

object EditorSpans {
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

  // special styles
  const val LINK = "link"
  const val IMAGE = "image"

  val inlineSpans: Map<String, BaseSpanConfig> = mapOf(
    BOLD to BaseSpanConfig(EditorBoldSpan::class.java),
    ITALIC to BaseSpanConfig(EditorItalicSpan::class.java),
    UNDERLINE to BaseSpanConfig(EditorUnderlineSpan::class.java),
    STRIKETHROUGH to BaseSpanConfig(EditorStrikeThroughSpan::class.java),
    INLINE_CODE to BaseSpanConfig(EditorInlineCodeSpan::class.java),
  )

  val paragraphSpans: Map<String, ParagraphSpanConfig> = mapOf(
    H1 to ParagraphSpanConfig(EditorH1Span::class.java, false),
    H2 to ParagraphSpanConfig(EditorH2Span::class.java, false),
    H3 to ParagraphSpanConfig(EditorH3Span::class.java, false),
    BLOCK_QUOTE to ParagraphSpanConfig(EditorBlockQuoteSpan::class.java, true),
    CODE_BLOCK to ParagraphSpanConfig(EditorCodeBlockSpan::class.java, true),
  )

  val listSpans: Map<String, ListSpanConfig> = mapOf(
    UNORDERED_LIST to ListSpanConfig(EditorUnorderedListSpan::class.java, "- "),
    ORDERED_LIST to ListSpanConfig(EditorOrderedListSpan::class.java, "1. "),
  )

  val specialStyles: Map<String, BaseSpanConfig> = mapOf(
    LINK to BaseSpanConfig(EditorLinkSpan::class.java),
    IMAGE to BaseSpanConfig(EditorImageSpan::class.java),
  )

  // TODO: provide proper config once other styles are implemented
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
    INLINE_CODE to StylesMergingConfig(),
    H1 to StylesMergingConfig(
      conflictingStyles = arrayOf(H2, H3, BLOCK_QUOTE, CODE_BLOCK),
    ),
    H2 to StylesMergingConfig(
      conflictingStyles = arrayOf(H1, H3, BLOCK_QUOTE, CODE_BLOCK),
    ),
    H3 to StylesMergingConfig(
      conflictingStyles = arrayOf(H1, H2, BLOCK_QUOTE, CODE_BLOCK),
    ),
    BLOCK_QUOTE to StylesMergingConfig(
      conflictingStyles = arrayOf(H1, H2, H3, CODE_BLOCK),
    ),
    CODE_BLOCK to StylesMergingConfig(
      conflictingStyles = arrayOf(H1, H2, H3, BOLD, ITALIC, UNDERLINE, STRIKETHROUGH, BLOCK_QUOTE),
    ),
    UNORDERED_LIST to StylesMergingConfig(
      conflictingStyles = arrayOf(H1, H2, H3, ORDERED_LIST),
    ),
    ORDERED_LIST to StylesMergingConfig(
      conflictingStyles = arrayOf(H1, H2, H3, UNORDERED_LIST),
    ),
    LINK to StylesMergingConfig(),
    IMAGE to StylesMergingConfig(),
  )
}
