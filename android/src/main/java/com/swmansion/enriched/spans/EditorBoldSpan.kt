package com.swmansion.enriched.spans

import android.graphics.Typeface
import android.text.style.StyleSpan
import com.swmansion.enriched.spans.interfaces.EditorInlineSpan
import com.swmansion.enriched.styles.RichTextStyle

@Suppress("UNUSED_PARAMETER")
class EditorBoldSpan(private val richTextStyle: RichTextStyle) : StyleSpan(Typeface.BOLD), EditorInlineSpan {
}
