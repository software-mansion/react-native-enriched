package com.swmansion.enriched.textinput.spans

import android.graphics.drawable.Drawable
import androidx.core.graphics.drawable.DrawableCompat
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
  isStaticPlaceholder: Boolean = false,
) : EnrichedImageSpan(drawable, source, width, height, isStaticPlaceholder),
  EnrichedInputSpan {
  override val dependsOnHtmlStyle: Boolean = false

  override fun rebuildWithStyle(htmlStyle: HtmlStyle): EnrichedInputImageSpan = this

  companion object {
    fun createEnrichedImageSpan(
      src: String,
      width: Int,
      height: Int,
      placeholderTintColor: Int,
    ): EnrichedInputImageSpan {
      var imgDrawable = prepareDrawableForImage(src, width, height, placeholderTintColor)
      var isStaticPlaceholder = false

      if (imgDrawable == null) {
        imgDrawable = ResourceManager.getDrawableResource(R.drawable.broken_image)
        isStaticPlaceholder = true
        DrawableCompat.setTint(imgDrawable, placeholderTintColor)
      }

      return EnrichedInputImageSpan(imgDrawable, src, width, height, isStaticPlaceholder)
    }
  }
}
