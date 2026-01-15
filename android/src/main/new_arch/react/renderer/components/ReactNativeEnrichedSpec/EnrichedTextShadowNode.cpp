#include "EnrichedTextShadowNode.h"

#include <react/renderer/core/LayoutContext.h>

namespace facebook::react {
extern const char EnrichedTextComponentName[] = "EnrichedTextView";
void EnrichedTextShadowNode::setMeasurementsManager(
    const std::shared_ptr<EnrichedTextMeasurementManager>
        &measurementsManager) {
  ensureUnsealed();
  measurementsManager_ = measurementsManager;
}

Size EnrichedTextShadowNode::measureContent(
    const LayoutContext &layoutContext,
    const LayoutConstraints &layoutConstraints) const {
  return measurementsManager_->measure(getSurfaceId(), getTag(),
                                       getConcreteProps(), layoutConstraints);
}

} // namespace facebook::react
