package com.swmansion.enriched.textinput.utils

import android.content.ClipData
import android.content.Context
import android.graphics.BitmapFactory
import android.net.Uri
import android.os.Handler
import android.os.Looper
import android.util.Log
import android.view.View
import androidx.core.view.ContentInfoCompat
import androidx.core.view.OnReceiveContentListener
import com.facebook.react.bridge.ReactContext
import com.facebook.react.uimanager.UIManagerHelper
import com.swmansion.enriched.textinput.EnrichedTextInputView
import com.swmansion.enriched.textinput.events.OnPasteImagesEvent
import com.swmansion.enriched.textinput.events.PastedImage
import java.io.File
import java.io.FileOutputStream
import java.util.UUID
import kotlin.io.copyTo

class RichContentReceiver(
  private val view: EnrichedTextInputView,
  private val context: ReactContext,
) : OnReceiveContentListener {
  override fun onReceiveContent(
    view: View,
    contentInfo: ContentInfoCompat,
  ): ContentInfoCompat? {
    val split = contentInfo.partition { item: ClipData.Item -> item.uri != null }
    val uriContent = split.first
    val remaining = split.second

    if (uriContent != null) {
      processClipDataInBackground(uriContent.clip)
    }

    if (remaining != null && remaining.clip.itemCount > 0) {
      val item = remaining.clip.getItemAt(0)

      this.view.handleTextPaste(item)
    }

    return null
  }

  private fun processClipDataInBackground(clip: ClipData) {
    Thread {
      val results = mutableListOf<PastedImage>()

      for (i in 0 until clip.itemCount) {
        val item = clip.getItemAt(i)
        val uri = item.uri ?: continue

        val mimeType = getMimeTypeFromUri(uri)

        if (mimeType.startsWith("image/")) {
          val result = saveUriToTempFile(context, uri, mimeType)
          if (result != null) {
            results.add(result)
          }
        }
      }

      if (results.isNotEmpty()) {
        Handler(Looper.getMainLooper()).post {
          emitOnPasteImageEvent(results)
        }
      }
    }.start()
  }

  private fun emitOnPasteImageEvent(images: List<PastedImage>) {
    val surfaceId = UIManagerHelper.getSurfaceId(context)
    val dispatcher = UIManagerHelper.getEventDispatcherForReactTag(context, view.id)
    dispatcher?.dispatchEvent(OnPasteImagesEvent(surfaceId, view.id, images, false))
  }

  private fun saveUriToTempFile(
    context: Context,
    uri: Uri,
    mimeType: String,
  ): PastedImage? {
    return try {
      val resolver = context.contentResolver

      // Guess Extension
      val ext =
        when {
          mimeType.contains("gif") -> "gif"
          mimeType.contains("png") -> "png"
          mimeType.contains("webp") -> "webp"
          mimeType.contains("heic") -> "heic"
          mimeType.contains("tiff") -> "tiff"
          else -> "jpg"
        }

      // Create Temp File
      val fileName = "${UUID.randomUUID()}.$ext"
      val file = File(context.cacheDir, fileName)

      // Copy Stream
      resolver.openInputStream(uri).use { input ->
        if (input == null) return null
        FileOutputStream(file).use { output ->
          input.copyTo(output)
        }
      }

      // Decode Dimensions
      val options = BitmapFactory.Options().apply { inJustDecodeBounds = true}
      BitmapFactory.decodeFile(file.absolutePath, options)

      PastedImage(
        uri = "file://${file.absolutePath}",
        type = mimeType,
        width = options.outWidth.toDouble(),
        height = options.outHeight.toDouble(),
      )
    } catch (e: Exception) {
      Log.e("RichContentReceiver", "Failed to save URI: $uri", e)
      null
    }
  }

  private fun getMimeTypeFromUri(uri: Uri): String {
    var mimeType = context.contentResolver.getType(uri)

    if (mimeType == null) {
      val str = uri.toString().lowercase()
      mimeType =
        when {
          str.contains("png") -> "image/png"
          str.contains("gif") -> "image/gif"
          str.contains("webp") -> "image/webp"
          str.contains("heic") -> "image/heic"
          str.contains("tiff") -> "image/tiff"
          else -> "image/jpeg"
        }
    }

    return mimeType
  }

  companion object {
    val MIME_TYPES = arrayOf("image/*", "text/*")
  }
}
