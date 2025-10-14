#include "EnrichedTextInputShadowNode.h"

#include <react/renderer/core/LayoutContext.h>

namespace facebook::react {
extern const char EnrichedTextInputComponentName[] = "EnrichedTextInputView";
    void EnrichedTextInputShadowNode::setMeasurementsManager(
            const std::shared_ptr<EnrichedTextInputMeasurementManager>&
            measurementsManager) {
        ensureUnsealed();
        measurementsManager_ = measurementsManager;
    }

    // Mark layout as dirty after state has been updated
    // Once layout is marked as dirty, `measureContent` will be called in order to recalculate layout
    void EnrichedTextInputShadowNode::dirtyLayoutIfNeeded() {
        const auto state = this->getStateData();
        const auto counter = state.getForceHeightRecalculationCounter();

        if (forceHeightRecalculationCounter_ != counter) {
            forceHeightRecalculationCounter_ = counter;

            dirtyLayout();
        }
    }

    Size EnrichedTextInputShadowNode::measureContent(
            const LayoutContext &layoutContext,
            const LayoutConstraints &layoutConstraints) const {

        return measurementsManager_->measure(getSurfaceId(), layoutConstraints);
    }

} // namespace facebook::react
