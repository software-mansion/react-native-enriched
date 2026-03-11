package com.swmansion.enriched.textinput.utils

import android.content.ClipData
import android.content.Context
import android.graphics.BitmapFactory
import android.net.Uri
import android.os.Handler
import android.os.Looper
import android.util.Log
import android.view.View
import android.webkit.MimeTypeMap
import androidx.core.view.ContentInfoCompat
import androidx.core.view.OnReceiveContentListener
import com.facebook.react.bridge.ReactContext
import com.facebook.react.uimanager.UIManagerHelper
import com.swmansion.enriched.textinput.EnrichedTextInputView
import com.swmansion.enriched.textinput.events.OnPasteImagesEvent
import java.io.File
import java.io.FileOutputStream
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
      val results = mutableListOf<OnPasteImagesEvent.Companion.PastedImage>()

      for (i in 0 until clip.itemCount) {
        val item = clip.getItemAt(i)
        val uri = item.uri ?: continue
        val mimeType = getMimeTypeFromUri(uri) ?: continue

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

  private fun emitOnPasteImageEvent(images: List<OnPasteImagesEvent.Companion.PastedImage>) {
    val surfaceId = UIManagerHelper.getSurfaceId(context)
    val dispatcher = UIManagerHelper.getEventDispatcherForReactTag(context, view.id)
    dispatcher?.dispatchEvent(OnPasteImagesEvent(surfaceId, view.id, images, false))
  }

  private fun saveUriToTempFile(
    context: Context,
    uri: Uri,
    mimeType: String,
  ): OnPasteImagesEvent.Companion.PastedImage? {
    return try {
      val resolver = context.contentResolver
      val ext = MimeTypeMap.getFileExtensionFromUrl(uri.toString())
      val file = File.createTempFile("temp", ".$ext", context.cacheDir)

      // Copy Stream
      resolver.openInputStream(uri).use { input ->
        if (input == null) return null
        FileOutputStream(file).use { output ->
          input.copyTo(output)
        }
      }

      // Decode Dimensions
      val options = BitmapFactory.Options().apply { inJustDecodeBounds = true }
      BitmapFactory.decodeFile(file.absolutePath, options)

      OnPasteImagesEvent.Companion.PastedImage(
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

  private fun getMimeTypeFromUri(uri: Uri): String? {
    var mimeType = context.contentResolver.getType(uri)

    if (mimeType == null) {
      val extension = MimeTypeMap.getFileExtensionFromUrl(uri.toString())

      mimeType = MimeTypeMap.getSingleton().getMimeTypeFromExtension(extension)
    }

    return mimeType
  }

  companion object {
    val MIME_TYPES = arrayOf("image/*", "text/*")
  }
}
