#pragma once

#include "EnrichedTextMeasurementManager.h"

#include <react/renderer/components/ReactNativeEnrichedSpec/EventEmitters.h>
#include <react/renderer/components/ReactNativeEnrichedSpec/Props.h>
#include <react/renderer/components/view/ConcreteViewShadowNode.h>

namespace facebook::react {

JSI_EXPORT extern const char EnrichedTextComponentName[];

class EnrichedTextShadowNode final
    : public ConcreteViewShadowNode<EnrichedTextComponentName,
                                    EnrichedTextViewProps,
                                    EnrichedTextViewEventEmitter> {
public:
  using ConcreteViewShadowNode::ConcreteViewShadowNode;

  static ShadowNodeTraits BaseTraits() {
    auto traits = ConcreteViewShadowNode::BaseTraits();
    traits.set(ShadowNodeTraits::Trait::LeafYogaNode);
    traits.set(ShadowNodeTraits::Trait::MeasurableYogaNode);
    return traits;
  }

  // Associates a shared `EnrichedTextMeasurementManager` with the node.
  void
  setMeasurementsManager(const std::shared_ptr<EnrichedTextMeasurementManager>
                             &measurementsManager);

  Size
  measureContent(const LayoutContext &layoutContext,
                 const LayoutConstraints &layoutConstraints) const override;

private:
  std::shared_ptr<EnrichedTextMeasurementManager> measurementsManager_;
};
} // namespace facebook::react
