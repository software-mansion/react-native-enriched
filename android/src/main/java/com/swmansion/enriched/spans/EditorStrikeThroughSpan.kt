package com.swmansion.enriched.spans

import android.text.style.StrikethroughSpan
import com.swmansion.enriched.spans.interfaces.EditorInlineSpan
import com.swmansion.enriched.styles.RichTextStyle

@Suppress("UNUSED_PARAMETER")
class EditorStrikeThroughSpan(private val richTextStyle: RichTextStyle) : StrikethroughSpan(), EditorInlineSpan {
}
