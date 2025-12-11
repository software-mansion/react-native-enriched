#pragma once
#include <memory>

namespace facebook::react {

class EnrichedTextInputViewState {
public:
  EnrichedTextInputViewState()
      : forceHeightRecalculationCounter_(0), componentViewRef_(nullptr) {}
  EnrichedTextInputViewState(int counter, std::shared_ptr<void> ref) {
    forceHeightRecalculationCounter_ = counter;
    componentViewRef_ = ref;
  }
  int getForceHeightRecalculationCounter() const;
  std::shared_ptr<void> getComponentViewRef() const;

private:
  int forceHeightRecalculationCounter_{};
  std::shared_ptr<void> componentViewRef_{};
};

} // namespace facebook::react
