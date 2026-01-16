package com.swmansion.enriched.textinput.spans

import com.swmansion.enriched.common.spans.EnrichedUnorderedListSpan
import com.swmansion.enriched.textinput.spans.interfaces.EnrichedInputSpan
import com.swmansion.enriched.textinput.styles.HtmlStyle

// https://android.googlesource.com/platform/frameworks/base/+/refs/heads/main/core/java/android/text/style/BulletSpan.java
class EnrichedInputUnorderedListSpan(
  htmlStyle: HtmlStyle,
) : EnrichedUnorderedListSpan(htmlStyle),
  EnrichedInputSpan {
  override val dependsOnHtmlStyle: Boolean = true

  override fun rebuildWithStyle(htmlStyle: HtmlStyle): EnrichedInputUnorderedListSpan = EnrichedInputUnorderedListSpan(htmlStyle)
}
