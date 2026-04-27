#include "EnrichedTextViewState.h"

namespace facebook::react {
std::shared_ptr<void> EnrichedTextViewState::getComponentViewRef() const {
  return componentViewRef_;
}
} // namespace facebook::react
