#pragma once

#include "EnrichedTextMeasurementManager.h"
#include "EnrichedTextShadowNode.h"

#include <react/renderer/core/ConcreteComponentDescriptor.h>

namespace facebook::react {

class EnrichedTextComponentDescriptor final
    : public ConcreteComponentDescriptor<EnrichedTextShadowNode> {
public:
  EnrichedTextComponentDescriptor(
      const ComponentDescriptorParameters &parameters)
      : ConcreteComponentDescriptor(parameters),
        measurementsManager_(std::make_shared<EnrichedTextMeasurementManager>(
            contextContainer_)) {}

  void adopt(ShadowNode &shadowNode) const override {
    ConcreteComponentDescriptor::adopt(shadowNode);
    auto &editorShadowNode = static_cast<EnrichedTextShadowNode &>(shadowNode);

    // `EnrichedTextShadowNode` uses
    // `EnrichedTextMeasurementManager` to provide measurements to Yoga.
    editorShadowNode.setMeasurementsManager(measurementsManager_);
  }

private:
  const std::shared_ptr<EnrichedTextMeasurementManager> measurementsManager_;
};

} // namespace facebook::react
