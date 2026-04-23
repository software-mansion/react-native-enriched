#pragma once
#include <memory>

namespace facebook::react {

class EnrichedTextViewState {
public:
  EnrichedTextViewState() : componentViewRef_(nullptr) {}
  explicit EnrichedTextViewState(std::shared_ptr<void> ref) {
    componentViewRef_ = ref;
  }
  std::shared_ptr<void> getComponentViewRef() const;

private:
  std::shared_ptr<void> componentViewRef_{};
};

} // namespace facebook::react
