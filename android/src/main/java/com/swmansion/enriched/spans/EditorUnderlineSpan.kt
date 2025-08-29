package com.swmansion.enriched.spans

import android.text.style.UnderlineSpan
import com.swmansion.enriched.spans.interfaces.EditorInlineSpan
import com.swmansion.enriched.styles.RichTextStyle

@Suppress("UNUSED_PARAMETER")
class EditorUnderlineSpan(private val richTextStyle: RichTextStyle) : UnderlineSpan(), EditorInlineSpan {
}
