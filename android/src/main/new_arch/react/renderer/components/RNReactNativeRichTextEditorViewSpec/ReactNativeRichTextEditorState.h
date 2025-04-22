// ReactNativeRichTextEditorState.h
#pragma once

#include <folly/dynamic.h>

namespace facebook::react {

class ReactNativeRichTextEditorState {
public:
  ReactNativeRichTextEditorState()
    : width_(0), height_(0) {}

  ReactNativeRichTextEditorState(float width, float height)
    : width_(width), height_(height) {}

  ReactNativeRichTextEditorState(ReactNativeRichTextEditorState const &previousState, folly::dynamic data)
    : width_((float)data["width"].getDouble()),
      height_((float)data["height"].getDouble()){};
  folly::dynamic getDynamic() const {
    return {};
  };

  float getWidth() const;
  float getHeight() const;

  private:
    const float width_{};
    const float height_{};
};

} // namespace facebook::react
