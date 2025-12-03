package com.swmansion.enriched.utils

import android.annotation.SuppressLint
import android.content.Context
import android.content.res.Resources
import android.graphics.drawable.Drawable
import androidx.core.content.res.ResourcesCompat
import androidx.core.graphics.drawable.DrawableCompat

object ResourceManager {
  private var appContext: Context? = null

  fun init(context: Context) {
    this.appContext = context.applicationContext
  }

  @SuppressLint("UseCompatLoadingForDrawables")
  fun getDrawableResource(id: Int): Drawable {
    val context = appContext ?: throw IllegalStateException("ResourceManager not initialized! Call init() first.")

    val image = ResourcesCompat.getDrawable(context.resources, id, null)
    val finalImage = image ?: Resources.getSystem().getDrawable(android.R.drawable.ic_menu_report_image)

    return DrawableCompat.wrap(finalImage)
  }
}
