#pragma once

#include "EnrichedTextInputMeasurementManager.h"
#include "EnrichedTextInputShadowNode.h"

#include <react/renderer/core/ConcreteComponentDescriptor.h>

namespace facebook::react {

class EnrichedTextInputComponentDescriptor final
    : public ConcreteComponentDescriptor<EnrichedTextInputShadowNode> {
public:
  EnrichedTextInputComponentDescriptor(
      const ComponentDescriptorParameters &parameters)
      : ConcreteComponentDescriptor(parameters),
        measurementsManager_(
            std::make_shared<EnrichedTextInputMeasurementManager>(
                contextContainer_)) {}

  void adopt(ShadowNode &shadowNode) const override {
    ConcreteComponentDescriptor::adopt(shadowNode);
    auto &editorShadowNode =
        static_cast<EnrichedTextInputShadowNode &>(shadowNode);

    // `EnrichedTextInputShadowNode` uses
    // `EnrichedTextInputMeasurementManager` to provide measurements to Yoga.
    editorShadowNode.setMeasurementsManager(measurementsManager_);
  }

private:
  const std::shared_ptr<EnrichedTextInputMeasurementManager>
      measurementsManager_;
};

} // namespace facebook::react
