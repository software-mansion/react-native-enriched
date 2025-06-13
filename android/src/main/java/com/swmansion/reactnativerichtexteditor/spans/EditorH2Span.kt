package com.swmansion.reactnativerichtexteditor.spans

import android.text.style.AbsoluteSizeSpan
import com.swmansion.reactnativerichtexteditor.spans.interfaces.EditorHeadingSpan
import com.swmansion.reactnativerichtexteditor.styles.RichTextStyle

class EditorH2Span(richTextStyle: RichTextStyle) : AbsoluteSizeSpan(richTextStyle.h2FontSize), EditorHeadingSpan {
}
