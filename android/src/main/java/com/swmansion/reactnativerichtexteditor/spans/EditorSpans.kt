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

  // paragraph styles
  const val H1 = "h1"
  const val H2 = "h2"
  const val H3 = "h3"

  // list styles
  const val UNORDERED_LIST = "unordered_list"
  const val ORDERED_LIST = "ordered_list"

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
  )

  val listSpans: Map<String, ListSpanConfig> = mapOf(
   UNORDERED_LIST to ListSpanConfig(EditorUnorderedListSpan::class.java, "- "),
    ORDERED_LIST to ListSpanConfig(EditorOrderedListSpan::class.java, "1. "),
  )

  // TODO: provider proper config once other styles are implemented
  val mergingConfig: Map<String, StylesMergingConfig> = mapOf(
    BOLD to StylesMergingConfig(),
    ITALIC to StylesMergingConfig(),
    UNDERLINE to StylesMergingConfig(),
    STRIKETHROUGH to StylesMergingConfig(),
    H1 to StylesMergingConfig(
      conflictingStyles = arrayOf(H2, H3),
    ),
    H2 to StylesMergingConfig(
      conflictingStyles = arrayOf(H1, H3),
    ),
    H3 to StylesMergingConfig(
      conflictingStyles = arrayOf(H1, H2),
    ),
    UNORDERED_LIST to StylesMergingConfig(
      conflictingStyles = arrayOf(H1, H2, H3, ORDERED_LIST),
    ),
    ORDERED_LIST to StylesMergingConfig(
      conflictingStyles = arrayOf(H1, H2, H3, UNORDERED_LIST),
    ),
  )
}
