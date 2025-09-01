#pragma once

#include "ComponentDescriptors.h"

#include <react/utils/ContextContainer.h>
#include <react/renderer/core/LayoutConstraints.h>
#include <react/renderer/components/RNEnrichedTextInputViewSpec/Props.h>

namespace facebook::react {

    class EnrichedTextInputMeasurementManager {
    public:
        EnrichedTextInputMeasurementManager(
                const ContextContainer::Shared& contextContainer)
                : contextContainer_(contextContainer) {}

        Size measure(
                SurfaceId surfaceId,
                const EnrichedTextInputViewProps& props,
                LayoutConstraints layoutConstraints) const;

    private:
        const ContextContainer::Shared contextContainer_;
    };

} // namespace facebook::react
