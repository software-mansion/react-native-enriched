package com.swmansion.reactnativerichtexteditor.spans

import android.text.style.StrikethroughSpan
import com.swmansion.reactnativerichtexteditor.spans.interfaces.EditorInlineSpan
import com.swmansion.reactnativerichtexteditor.styles.RichTextStyle

@Suppress("UNUSED_PARAMETER")
class EditorStrikeThroughSpan(private val richTextStyle: RichTextStyle) : StrikethroughSpan(), EditorInlineSpan {
}
