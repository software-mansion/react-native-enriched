#include "EnrichedTextInputViewShadowNode.h"

namespace facebook::react {

extern const char EnrichedTextInputViewComponentName[] =
    "EnrichedTextInputView";

void EnrichedTextInputViewShadowNode::dirtyLayoutIfNeeded() {
  const auto &state = getStateData();

  auto nextSize = state.getContentSize();
  if (nextSize != _prevContentSize) {
    _prevContentSize = nextSize;
    YGNodeMarkDirty(&yogaNode_);
  }
}

Size EnrichedTextInputViewShadowNode::measureContent(
    const LayoutContext &, const LayoutConstraints &constraints) const {

  const auto size = getStateData().getContentSize();
  return constraints.clamp(size);
}

} // namespace facebook::react
