#pragma once

#include "RichTextEditorMeasurementManager.h"
#include "ReactNativeRichTextEditorShadowNode.h"

#include <react/renderer/core/ConcreteComponentDescriptor.h>

namespace facebook::react {

class ReactNativeRichTextEditorViewComponentDescriptor final
        : public ConcreteComponentDescriptor<ReactNativeRichTextEditorShadowNode> {
public:
    ReactNativeRichTextEditorViewComponentDescriptor(
            const ComponentDescriptorParameters& parameters)
        : ConcreteComponentDescriptor(parameters),
            measurementsManager_(
                std::make_shared<RichTextEditorMeasurementManager>(
                        contextContainer_)) {}

    void adopt(ShadowNode& shadowNode) const override {
        ConcreteComponentDescriptor::adopt(shadowNode);
        auto& editorShadowNode = static_cast<ReactNativeRichTextEditorShadowNode&>(shadowNode);

        // `ReactNativeRichTextEditorShadowNode` uses
        // `RichTextEditorMeasurementManager` to provide measurements to Yoga.
        editorShadowNode.setMeasurementsManager(measurementsManager_);
    }

private:
    const std::shared_ptr<RichTextEditorMeasurementManager>
            measurementsManager_;
};

} // namespace facebook::react

