#include "EnrichedTextInputViewState.h"

namespace facebook::react {
int EnrichedTextInputViewState::getForceHeightRecalculationCounter() const {
  return forceHeightRecalculationCounter_;
}
std::shared_ptr<void> EnrichedTextInputViewState::getComponentViewRef() const {
  return componentViewRef_;
}
} // namespace facebook::react
