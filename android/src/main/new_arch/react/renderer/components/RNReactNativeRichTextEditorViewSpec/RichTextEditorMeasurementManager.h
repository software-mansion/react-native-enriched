#pragma once

#include "ComponentDescriptors.h"

#include <react/utils/ContextContainer.h>
#include <react/renderer/core/LayoutConstraints.h>
#include <react/renderer/components/RNReactNativeRichTextEditorViewSpec/Props.h>

namespace facebook::react {

    class RichTextEditorMeasurementManager {
    public:
        RichTextEditorMeasurementManager(
                const ContextContainer::Shared& contextContainer)
                : contextContainer_(contextContainer) {}

        Size measure(
                SurfaceId surfaceId,
                const ReactNativeRichTextEditorViewProps& props,
                LayoutConstraints layoutConstraints) const;

    private:
        const ContextContainer::Shared contextContainer_;
    };

} // namespace facebook::react
