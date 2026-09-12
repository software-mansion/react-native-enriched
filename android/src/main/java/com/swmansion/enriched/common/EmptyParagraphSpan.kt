package com.swmansion.enriched.common

import android.text.style.ParagraphStyle

// A no-op ParagraphStyle. Setting one over a range forces
// Android to re-layout it.
class EmptyParagraphSpan : ParagraphStyle
