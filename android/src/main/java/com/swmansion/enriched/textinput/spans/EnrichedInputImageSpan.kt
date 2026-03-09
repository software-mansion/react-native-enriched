package com.swmansion.enriched.textinput.spans

import android.graphics.drawable.Drawable
import com.swmansion.enriched.R
import com.swmansion.enriched.common.ResourceManager
import com.swmansion.enriched.common.spans.EnrichedImageSpan
import com.swmansion.enriched.textinput.spans.interfaces.EnrichedInputSpan
import com.swmansion.enriched.textinput.styles.HtmlStyle

class EnrichedInputImageSpan(
  drawable: Drawable,
  source: String,
  width: Int,
  height: Int,
) : EnrichedImageSpan(drawable, source, width, height),
  EnrichedInputSpan {
  override val dependsOnHtmlStyle: Boolean = false

  override fun rebuildWithStyle(htmlStyle: HtmlStyle): EnrichedInputImageSpan = this

  companion object {
    fun createEnrichedImageSpan(
      src: String,
      width: Int,
      height: Int,
    ): EnrichedInputImageSpan {
      var imgDrawable = prepareDrawableForImage(src, width, height)

      if (imgDrawable == null) {
        imgDrawable = ResourceManager.getDrawableResource(R.drawable.broken_image)
      }

      return EnrichedInputImageSpan(imgDrawable, src, width, height)
    }
  }
}
