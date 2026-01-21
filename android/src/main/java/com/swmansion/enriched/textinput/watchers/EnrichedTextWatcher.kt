package com.swmansion.enriched.textinput.watchers

import android.text.Editable
import android.text.TextWatcher
import com.facebook.react.bridge.ReactContext
import com.facebook.react.uimanager.UIManagerHelper
import com.swmansion.enriched.textinput.EnrichedTextInputView
import com.swmansion.enriched.textinput.events.OnChangeTextEvent

class EnrichedTextWatcher(
  private val view: EnrichedTextInputView,
) : TextWatcher {
  private var endCursorPosition: Int = 0
  private var startCursorPosition: Int = 0
  private var previousTextLength: Int = 0

  override fun beforeTextChanged(
    s: CharSequence?,
    start: Int,
    count: Int,
    after: Int,
  ) {
    previousTextLength = s?.length ?: 0
  }

  override fun onTextChanged(
    s: CharSequence?,
    start: Int,
    before: Int,
    count: Int,
  ) {
    startCursorPosition = start
    endCursorPosition = start + count
    view.layoutManager.invalidateLayout()
    view.isRemovingMany = !view.isDuringTransaction && before > count + 1
  }

  override fun afterTextChanged(s: Editable?) {
    if (s == null) return
    emitEvents(s)

    if (view.isDuringTransaction) return
    applyStyles(s)
  }

  private fun applyStyles(s: Editable) {
    view.inlineStyles?.afterTextChanged(s, endCursorPosition)
    view.paragraphStyles?.afterTextChanged(s, endCursorPosition, previousTextLength)
    view.listStyles?.afterTextChanged(s, endCursorPosition, previousTextLength)
    view.parametrizedStyles?.afterTextChanged(s, startCursorPosition, endCursorPosition)
  }

  private fun emitChangeText(editable: Editable) {
    if (!view.shouldEmitOnChangeText) {
      return
    }
    val context = view.context as ReactContext
    val surfaceId = UIManagerHelper.getSurfaceId(context)
    val dispatcher = UIManagerHelper.getEventDispatcherForReactTag(context, view.id)
    dispatcher?.dispatchEvent(
      OnChangeTextEvent(
        surfaceId,
        view.id,
        editable,
        view.experimentalSynchronousEvents,
      ),
    )
  }

  private fun emitEvents(s: Editable) {
    emitChangeText(s)
    view.spanWatcher?.emitEvent(s, null)
  }
}
