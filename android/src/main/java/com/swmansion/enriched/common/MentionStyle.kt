package com.swmansion.enriched.common

data class MentionStyle(
  val color: Int,
  val backgroundColor: Int,
  val underline: Boolean,
  val pressColor: Int? = null,
  val pressBackgroundColor: Int? = null,
)
