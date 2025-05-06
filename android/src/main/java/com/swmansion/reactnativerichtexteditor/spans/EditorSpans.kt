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
  const val INLINE_CODE = "inline_code"

  // paragraph styles
  const val H1 = "h1"
  const val H2 = "h2"
  const val H3 = "h3"

  // special styles
  const val LINK = "link"

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
  )

  val specialStyles: Map<String, BaseSpanConfig> = mapOf(
    LINK to BaseSpanConfig(EditorLinkSpan::class.java),
  )

  // TODO: provide proper config once other styles are implemented
  val mergingConfig: Map<String, StylesMergingConfig> = mapOf(
    BOLD to StylesMergingConfig(),
    ITALIC to StylesMergingConfig(),
    UNDERLINE to StylesMergingConfig(),
    STRIKETHROUGH to StylesMergingConfig(),
    INLINE_CODE to StylesMergingConfig(),
    H1 to StylesMergingConfig(
      conflictingStyles = arrayOf(H2, H3),
    ),
    H2 to StylesMergingConfig(
      conflictingStyles = arrayOf(H1, H3),
    ),
    H3 to StylesMergingConfig(
      conflictingStyles = arrayOf(H1, H2),
    ),
    LINK to StylesMergingConfig(),
  )
}
