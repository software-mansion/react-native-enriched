package com.swmansion.enriched.text.spans

import android.graphics.drawable.Drawable
import com.swmansion.enriched.R
import com.swmansion.enriched.common.ResourceManager
import com.swmansion.enriched.common.spans.EnrichedImageSpan
import com.swmansion.enriched.text.EnrichedTextStyle
import com.swmansion.enriched.text.spans.interfaces.EnrichedTextSpan

class EnrichedTextImageSpan(
  drawable: Drawable,
  source: String,
  width: Int,
  height: Int,
) : EnrichedImageSpan(drawable, source, width, height),
  EnrichedTextSpan {
  override val dependsOnHtmlStyle = false

  override fun rebuildWithStyle(style: EnrichedTextStyle) = this

  companion object {
    fun createEnrichedImageSpan(
      src: String,
      width: Int,
      height: Int,
    ): EnrichedImageSpan {
      var imgDrawable = prepareDrawableForImage(src)

      if (imgDrawable == null) {
        imgDrawable = ResourceManager.getDrawableResource(R.drawable.broken_image)
      }

      return EnrichedTextImageSpan(imgDrawable, src, width, height)
    }
  }
}
