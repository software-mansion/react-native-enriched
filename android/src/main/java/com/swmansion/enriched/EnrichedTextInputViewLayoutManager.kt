package com.swmansion.enriched

import android.graphics.text.LineBreaker
import android.os.Build
import android.text.Editable
import android.text.StaticLayout
import com.facebook.react.bridge.Arguments
import com.facebook.react.uimanager.PixelUtil

class EnrichedTextInputViewLayoutManager(private val view: EnrichedTextInputView) {
  private var cachedSize: Pair<Float, Float> = Pair(0f, 0f)
  private var cachedYogaWidth: Float = 0f
  private var forceHeightRecalculationCounter: Int = 0

  fun cleanup() {
    forceHeightRecalculationCounter = 0
  }

  // Update shadow node's state in order to recalculate layout
  fun invalidateLayout(text: Editable?) {
    measureSize(text ?: "")

    val counter = forceHeightRecalculationCounter
    forceHeightRecalculationCounter++
    val state = Arguments.createMap()
    state.putInt("forceHeightRecalculationCounter", counter)
    view.stateWrapper?.updateState(state)
  }

  fun getMeasuredSize(maxWidth: Float): Pair<Float, Float> {
    if (maxWidth == cachedYogaWidth) {
      return cachedSize
    }

    val text = view.text ?: ""
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
    val paint = view.paint
    val textLength = text.length

    val builder = StaticLayout.Builder
      .obtain(text, 0, textLength, paint, maxWidth.toInt())
      .setIncludePad(true)
      .setLineSpacing(0f, 1f)

    if (Build.VERSION.SDK_INT >= Build.VERSION_CODES.Q) {
      builder.setBreakStrategy(LineBreaker.BREAK_STRATEGY_HIGH_QUALITY)
    }

    if (Build.VERSION.SDK_INT >= Build.VERSION_CODES.P) {
      builder.setUseLineSpacingFromFallbacks(true)
    }

    val staticLayout = builder.build()
    val heightInSP = PixelUtil.toDIPFromPixel(staticLayout.height.toFloat())
    val widthInSP = PixelUtil.toDIPFromPixel(maxWidth)

    return Pair(widthInSP, heightInSP)
  }
}
