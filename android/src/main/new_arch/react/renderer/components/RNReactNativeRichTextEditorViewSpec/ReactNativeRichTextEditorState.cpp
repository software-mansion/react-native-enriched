#include <react/renderer/components/RNReactNativeRichTextEditorViewSpec/ReactNativeRichTextEditorState.h>

namespace facebook::react {

float ReactNativeRichTextEditorState::getWidth() const {
  return width_;
}

float ReactNativeRichTextEditorState::getHeight() const {
  return height_;
}
} // namespace facebook::react
