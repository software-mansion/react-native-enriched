#pragma once
#include <react/renderer/graphics/Size.h>

namespace facebook::react {

class EnrichedTextInputViewState {
public:
  EnrichedTextInputViewState() = default;

  explicit EnrichedTextInputViewState(Size contentSize,
                                      std::shared_ptr<void> ref)
      : contentSize_(contentSize), componentViewRef_(std::move(ref)) {}

  const Size &getContentSize() const { return contentSize_; }

  const std::shared_ptr<void> getComponentViewRef() const {
    return componentViewRef_;
  }

private:
  Size contentSize_{};
  std::shared_ptr<void> componentViewRef_{};
};

} // namespace facebook::react
