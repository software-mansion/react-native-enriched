// ReactNativeRichTextEditorState.h
#pragma once

#ifdef ANDROID
#include <folly/dynamic.h>
#endif

namespace facebook::react {

class ReactNativeRichTextEditorState {
public:
  ReactNativeRichTextEditorState() = default;
#ifdef ANDROID
  ReactNativeRichTextEditorState(ReactNativeRichTextEditorState const &previousState, folly::dynamic data){};
  folly::dynamic getDynamic() const {
    return {};
  };
#endif
};

} // namespace facebook::react
