package com.swmansion.reactnativerichtexteditor.spans

data class BaseSpanConfig(val clazz: Class<*>)
data class ParagraphSpanConfig(val clazz: Class<*>, val isContinuous: Boolean)

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

  // paragraph styles
  const val H1 = "h1"
  const val H2 = "h2"
  const val H3 = "h3"
  const val BLOCK_QUOTE = "block_quote"
  const val CODE_BLOCK = "code_block"

  val inlineSpans: Map<String, BaseSpanConfig> = mapOf(
    BOLD to BaseSpanConfig(EditorBoldSpan::class.java),
    ITALIC to BaseSpanConfig(EditorItalicSpan::class.java),
    UNDERLINE to BaseSpanConfig(EditorUnderlineSpan::class.java),
    STRIKETHROUGH to BaseSpanConfig(EditorStrikeThroughSpan::class.java),
  )

  val paragraphSpans: Map<String, ParagraphSpanConfig> = mapOf(
    H1 to ParagraphSpanConfig(EditorH1Span::class.java, false),
    H2 to ParagraphSpanConfig(EditorH2Span::class.java, false),
    H3 to ParagraphSpanConfig(EditorH3Span::class.java, false),
    BLOCK_QUOTE to ParagraphSpanConfig(EditorBlockQuoteSpan::class.java, true),
    CODE_BLOCK to ParagraphSpanConfig(EditorCodeBlockSpan::class.java, true),
  )

  // TODO: provider proper config once other styles are implemented
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
  )
}
