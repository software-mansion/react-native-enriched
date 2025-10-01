#pragma once

#include "ComponentDescriptors.h"

#include <react/utils/ContextContainer.h>
#include <react/renderer/core/LayoutConstraints.h>
#include <react/renderer/components/RNEnrichedTextInputViewSpec/Props.h>

namespace facebook::react {

    class EnrichedTextInputMeasurementManager {
    public:
        EnrichedTextInputMeasurementManager(
                const std::shared_ptr<const ContextContainer>& contextContainer)
                : contextContainer_(contextContainer) {}

        Size measure(
                SurfaceId surfaceId,
                const EnrichedTextInputViewProps& props,
                LayoutConstraints layoutConstraints) const;

    private:
        const std::shared_ptr<const ContextContainer> contextContainer_;
    };

} // namespace facebook::react
