package com.swmansion.reactnativerichtexteditor.spans

import android.text.style.AbsoluteSizeSpan
import com.swmansion.reactnativerichtexteditor.spans.interfaces.EditorHeadingSpan
import com.swmansion.reactnativerichtexteditor.styles.RichTextStyle

class EditorH1Span(style: RichTextStyle) : AbsoluteSizeSpan(style.h1FontSize), EditorHeadingSpan {
}
