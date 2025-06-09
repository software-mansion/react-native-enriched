package com.swmansion.reactnativerichtexteditor.spans

import android.text.style.AbsoluteSizeSpan
import com.swmansion.reactnativerichtexteditor.spans.interfaces.EditorHeadingSpan
import com.swmansion.reactnativerichtexteditor.spans.interfaces.EditorInlineSpan
import com.swmansion.reactnativerichtexteditor.spans.interfaces.EditorZeroWidthSpaceSpan
import com.swmansion.reactnativerichtexteditor.styles.RichTextStyle

// Heading spans inherit from EditorInlineSpan because they can be nested inside code block and block quote
class EditorH1Span(style: RichTextStyle) : AbsoluteSizeSpan(style.h1FontSize), EditorHeadingSpan, EditorInlineSpan, EditorZeroWidthSpaceSpan {
}
