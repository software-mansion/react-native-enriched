package com.swmansion.reactnativerichtexteditor.spans

import android.graphics.Typeface
import android.text.style.StyleSpan
import com.swmansion.reactnativerichtexteditor.spans.interfaces.EditorInlineSpan
import com.swmansion.reactnativerichtexteditor.styles.RichTextStyle

@Suppress("UNUSED_PARAMETER")
class EditorBoldSpan(private val richTextStyle: RichTextStyle) : StyleSpan(Typeface.BOLD), EditorInlineSpan {
}
