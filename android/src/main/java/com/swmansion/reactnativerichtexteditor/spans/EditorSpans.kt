package com.swmansion.reactnativerichtexteditor.spans

data class BaseSpanConfig(val clazz: Class<*>)

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

  // special styles
  const val LINK = "link"

  val inlineSpans: Map<String, BaseSpanConfig> = mapOf(
    BOLD to BaseSpanConfig(EditorBoldSpan::class.java),
    ITALIC to BaseSpanConfig(EditorItalicSpan::class.java),
    UNDERLINE to BaseSpanConfig(EditorUnderlineSpan::class.java),
    STRIKETHROUGH to BaseSpanConfig(EditorStrikeThroughSpan::class.java),
  )

  val specialStyles: Map<String, BaseSpanConfig> = mapOf(
    LINK to BaseSpanConfig(EditorLinkSpan::class.java),
  )

  // TODO: provider proper config once other styles are implemented
  val mergingConfig: Map<String, StylesMergingConfig> = mapOf(
    BOLD to StylesMergingConfig(),
    ITALIC to StylesMergingConfig(),
    UNDERLINE to StylesMergingConfig(),
    STRIKETHROUGH to StylesMergingConfig(),
    LINK to StylesMergingConfig(),
  )
}
