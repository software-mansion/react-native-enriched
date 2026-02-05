#pragma once

#include "ComponentDescriptors.h"

#include <react/renderer/components/ReactNativeEnrichedSpec/Props.h>
#include <react/renderer/core/LayoutConstraints.h>
#include <react/utils/ContextContainer.h>

namespace facebook::react {

class EnrichedTextMeasurementManager {
public:
  EnrichedTextMeasurementManager(
      const std::shared_ptr<const ContextContainer> &contextContainer)
      : contextContainer_(contextContainer) {}

  Size measure(SurfaceId surfaceId, int viewTag,
               const EnrichedTextViewProps &props,
               LayoutConstraints layoutConstraints) const;

private:
  const std::shared_ptr<const ContextContainer> contextContainer_;
};

} // namespace facebook::react
