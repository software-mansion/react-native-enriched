package com.swmansion.enriched.textinput

import android.text.Editable
import android.view.KeyEvent
import android.view.inputmethod.BaseInputConnection
import android.view.inputmethod.InputConnection
import android.view.inputmethod.InputConnectionWrapper
import com.facebook.react.bridge.ReactContext
import com.facebook.react.uimanager.UIManagerHelper
import com.swmansion.enriched.textinput.events.OnInputKeyPressEvent
import com.swmansion.enriched.textinput.spans.EnrichedSpans

// This class is based on the implementation from Facebook React Native to provide 'onKeyPress' API on android.
// Original source:
// https://github.com/facebook/react-native/blob/v0.83.1/packages/react-native/ReactAndroid/src/main/java/com/facebook/react/views/textinput/ReactEditTextInputConnectionWrapper.kt
class EnrichedTextInputConnectionWrapper(
  target: InputConnection,
  private val reactContext: ReactContext,
  private val editText: EnrichedTextInputView,
  private val experimentalSynchronousEvents: Boolean,
) : InputConnectionWrapper(target, false) {
  private data class InlineSpanSnapshot(
    val style: String,
    val start: Int,
    val end: Int,
  )

  private data class ComposingTextSnapshot(
    val start: Int,
    val end: Int,
    val editableLength: Int,
    val text: String,
    val inlineSpans: List<InlineSpanSnapshot>,
  )

  private var isBatchEdit = false
  private var key: String? = null

  override fun beginBatchEdit(): Boolean {
    isBatchEdit = true
    return super.beginBatchEdit()
  }

  override fun endBatchEdit(): Boolean {
    isBatchEdit = false
    key?.let { k ->
      dispatchKeyEvent(k)
      key = null
    }
    return super.endBatchEdit()
  }

  override fun setComposingText(
    text: CharSequence,
    newCursorPosition: Int,
  ): Boolean {
    val previousSelectionStart = editText.selectionStart
    val previousSelectionEnd = editText.selectionEnd
    val composingTextSnapshot = captureComposingText()

    val consumed = super.setComposingText(text, newCursorPosition)

    if (consumed && composingTextSnapshot != null) {
      restoreInlineSpans(composingTextSnapshot)
    }

    val currentSelectionStart = editText.selectionStart
    val noPreviousSelection = previousSelectionStart == previousSelectionEnd
    val cursorDidNotMove = currentSelectionStart == previousSelectionStart
    val cursorMovedBackwardsOrAtBeginningOfInput =
      currentSelectionStart < previousSelectionStart || currentSelectionStart <= 0

    val inputKey =
      if (
        cursorMovedBackwardsOrAtBeginningOfInput || (!noPreviousSelection && cursorDidNotMove)
      ) {
        BACKSPACE_KEY_VALUE
      } else {
        editText.text?.get(currentSelectionStart - 1).toString()
      }

    dispatchKeyEventOrEnqueue(inputKey)
    return consumed
  }

  // Snapshots the inline styles carried by the text the IME is about to replace. Returns null
  // whenever there is nothing to preserve, which keeps plain typing down to a single span lookup.
  private fun captureComposingText(): ComposingTextSnapshot? {
    val editable = editText.text ?: return null
    val composingStart = BaseInputConnection.getComposingSpanStart(editable)
    val composingEnd = BaseInputConnection.getComposingSpanEnd(editable)
    if (composingStart < 0 || composingEnd <= composingStart) return null

    val inlineSpans = captureInlineSpans(editable, composingStart, composingEnd)
    if (inlineSpans.isEmpty()) return null

    return ComposingTextSnapshot(
      start = composingStart,
      end = composingEnd,
      editableLength = editable.length,
      text = editable.substring(composingStart, composingEnd),
      inlineSpans = inlineSpans,
    )
  }

  private fun captureInlineSpans(
    editable: Editable,
    composingStart: Int,
    composingEnd: Int,
  ): List<InlineSpanSnapshot> =
    EnrichedSpans.inlineSpans.flatMap { (style, config) ->
      editable.getSpans(composingStart, composingEnd, config.clazz).mapNotNull { span ->
        val start = editable.getSpanStart(span).coerceAtLeast(composingStart)
        val end = editable.getSpanEnd(span).coerceAtMost(composingEnd)

        if (start < end) {
          InlineSpanSnapshot(style, start - composingStart, end - composingStart)
        } else {
          null
        }
      }
    }

  private fun restoreInlineSpans(snapshot: ComposingTextSnapshot) {
    val editable = editText.text ?: return
    val previousComposingLength = snapshot.end - snapshot.start
    val currentComposingLength =
      editable.length - (snapshot.editableLength - previousComposingLength)
    val currentComposingStart = snapshot.start.coerceAtMost(editable.length)
    val currentComposingEnd =
      (currentComposingStart + currentComposingLength)
        .coerceAtLeast(currentComposingStart)
        .coerceAtMost(editable.length)
    if (currentComposingStart >= currentComposingEnd) return

    val currentComposingText = editable.substring(currentComposingStart, currentComposingEnd)
    val commonPrefixLength = commonPrefixLength(snapshot.text, currentComposingText)
    val commonSuffixLength =
      commonSuffixLength(
        snapshot.text,
        currentComposingText,
        commonPrefixLength,
      )

    for (inlineSpan in snapshot.inlineSpans) {
      restoreSnapshotIntersection(
        inlineSpan,
        oldRangeStart = 0,
        oldRangeEnd = commonPrefixLength,
        newRangeStart = 0,
        composingStart = currentComposingStart,
      )

      val previousSuffixStart = snapshot.text.length - commonSuffixLength
      val currentSuffixStart = currentComposingText.length - commonSuffixLength
      restoreSnapshotIntersection(
        inlineSpan,
        oldRangeStart = previousSuffixStart,
        oldRangeEnd = snapshot.text.length,
        newRangeStart = currentSuffixStart,
        composingStart = currentComposingStart,
      )
    }
  }

  private fun restoreSnapshotIntersection(
    snapshot: InlineSpanSnapshot,
    oldRangeStart: Int,
    oldRangeEnd: Int,
    newRangeStart: Int,
    composingStart: Int,
  ) {
    val intersectionStart = snapshot.start.coerceAtLeast(oldRangeStart)
    val intersectionEnd = snapshot.end.coerceAtMost(oldRangeEnd)
    if (intersectionStart >= intersectionEnd) return

    val mappedStart = newRangeStart + intersectionStart - oldRangeStart
    val mappedEnd = newRangeStart + intersectionEnd - oldRangeStart
    editText.inlineStyles?.applyStyleOnRange(
      snapshot.style,
      composingStart + mappedStart,
      composingStart + mappedEnd,
    )
  }

  private fun commonPrefixLength(
    previousText: String,
    currentText: String,
  ): Int {
    val maximum = minOf(previousText.length, currentText.length)
    var length = 0
    while (length < maximum && previousText[length] == currentText[length]) {
      length++
    }
    return length
  }

  private fun commonSuffixLength(
    previousText: String,
    currentText: String,
    commonPrefixLength: Int,
  ): Int {
    val maximum =
      minOf(
        previousText.length - commonPrefixLength,
        currentText.length - commonPrefixLength,
      )
    var length = 0
    while (
      length < maximum &&
      previousText[previousText.lastIndex - length] == currentText[currentText.lastIndex - length]
    ) {
      length++
    }
    return length
  }

  override fun commitText(
    text: CharSequence,
    newCursorPosition: Int,
  ): Boolean {
    var inputKey = text.toString()
    // Assume not a keyPress if length > 1 (or 2 if unicode)
    if (inputKey.length <= 2) {
      if (inputKey.isEmpty()) {
        inputKey = BACKSPACE_KEY_VALUE
      }
      dispatchKeyEventOrEnqueue(inputKey)
    }

    val composingTextSnapshot = captureComposingText()
    val consumed = super.commitText(text, newCursorPosition)
    if (consumed && composingTextSnapshot != null) {
      restoreInlineSpans(composingTextSnapshot)
    }
    return consumed
  }

  override fun deleteSurroundingText(
    beforeLength: Int,
    afterLength: Int,
  ): Boolean {
    dispatchKeyEvent(BACKSPACE_KEY_VALUE)
    return super.deleteSurroundingText(beforeLength, afterLength)
  }

  // Called by SwiftKey when cursor at beginning of input when there is a delete
  // or when enter is pressed anywhere in the text. Whereas stock Android Keyboard calls
  // [InputConnection.deleteSurroundingText] & [InputConnection.commitText]
  // in each case, respectively.
  override fun sendKeyEvent(event: KeyEvent): Boolean {
    if (event.action == KeyEvent.ACTION_DOWN) {
      val isNumberKey = event.unicodeChar in 48..57
      when (event.keyCode) {
        KeyEvent.KEYCODE_DEL -> {
          dispatchKeyEvent(BACKSPACE_KEY_VALUE)
        }

        KeyEvent.KEYCODE_ENTER -> {
          dispatchKeyEvent(ENTER_KEY_VALUE)
        }

        else -> {
          if (isNumberKey) {
            dispatchKeyEvent(event.number.toString())
          }
        }
      }
    }
    return super.sendKeyEvent(event)
  }

  private fun dispatchKeyEventOrEnqueue(inputKey: String) {
    if (isBatchEdit) {
      key = inputKey
    } else {
      dispatchKeyEvent(inputKey)
    }
  }

  private fun dispatchKeyEvent(inputKey: String) {
    val resolvedKey = if (inputKey == NEWLINE_RAW_VALUE) ENTER_KEY_VALUE else inputKey
    val surfaceId = UIManagerHelper.getSurfaceId(editText)
    val eventDispatcher = UIManagerHelper.getEventDispatcherForReactTag(reactContext, editText.id)
    eventDispatcher?.dispatchEvent(
      OnInputKeyPressEvent(
        surfaceId = surfaceId,
        viewId = editText.id,
        key = resolvedKey,
        experimentalSynchronousEvents = experimentalSynchronousEvents,
      ),
    )
  }

  companion object {
    const val NEWLINE_RAW_VALUE: String = "\n"
    const val BACKSPACE_KEY_VALUE: String = "Backspace"
    const val ENTER_KEY_VALUE: String = "Enter"
  }
}
