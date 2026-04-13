#pragma once
#include <ReactNativeEnriched/EnrichedTextViewShadowNode.h>
#include <ReactNativeEnriched/Props.h>
#include <react/debug/react_native_assert.h>
#include <react/renderer/core/ConcreteComponentDescriptor.h>

namespace facebook::react {
class EnrichedTextComponentDescriptor final
    : public ConcreteComponentDescriptor<EnrichedTextViewShadowNode> {
public:
  using ConcreteComponentDescriptor::ConcreteComponentDescriptor;
  void adopt(ShadowNode &shadowNode) const override {
    react_native_assert(
        dynamic_cast<EnrichedTextViewShadowNode *>(&shadowNode));
    ConcreteComponentDescriptor::adopt(shadowNode);
  }
};

} // namespace facebook::react
