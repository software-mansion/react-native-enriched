package com.swmansion.reactnativerichtexteditor

import android.text.StaticLayout
import com.facebook.react.uimanager.PixelUtil

class ReactNativeRichTextEditorViewLayoutManager(private val editorView: ReactNativeRichTextEditorView) {
  private var cachedSize: Pair<Float, Float> = Pair(0f, 0f)
  private var cachedYogaWidth: Float = 0f

  fun getMeasuredSize(maxWidth: Float): Pair<Float, Float> {
    if (maxWidth == cachedYogaWidth) {
      return cachedSize
    }

    val text = editorView.text ?: ""
    val result = measureAndCacheSize(text, maxWidth)
    cachedYogaWidth = maxWidth
    return result
  }

  fun measureSize(text: CharSequence): Pair<Float, Float> {
    return measureAndCacheSize(text, cachedYogaWidth)
  }

  private fun measureAndCacheSize(text: CharSequence, maxWidth: Float): Pair<Float, Float> {
    val result = measureSize(text, maxWidth)
    cachedSize = result
    return result
  }

  private fun measureSize(text: CharSequence, maxWidth: Float): Pair<Float, Float> {
    val paint = editorView.paint
    val textLength = text.length

    val staticLayout = StaticLayout.Builder
      .obtain(text, 0, textLength, paint, maxWidth.toInt())
      .setIncludePad(true)
      .setLineSpacing(0f, 1f)
      .build()

    val heightInSP = PixelUtil.toDIPFromPixel(staticLayout.height.toFloat())
    val widthInSP = PixelUtil.toDIPFromPixel(maxWidth)

    return Pair(widthInSP, heightInSP)
  }
}
