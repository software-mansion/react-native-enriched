package com.swmansion.reactnativerichtexteditor.spans

import android.text.style.UnderlineSpan
import com.swmansion.reactnativerichtexteditor.spans.interfaces.EditorInlineSpan
import com.swmansion.reactnativerichtexteditor.styles.RichTextStyle

@Suppress("UNUSED_PARAMETER")
class EditorUnderlineSpan(private val richTextStyle: RichTextStyle) : UnderlineSpan(), EditorInlineSpan {
}
