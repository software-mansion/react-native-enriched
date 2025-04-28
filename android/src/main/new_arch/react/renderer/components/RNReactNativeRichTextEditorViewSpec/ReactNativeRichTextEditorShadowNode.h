#pragma once

#include "RichTextEditorMeasurementManager.h"

#include <react/renderer/components/rncore/EventEmitters.h>
#include <react/renderer/components/view/ConcreteViewShadowNode.h>
#include <react/renderer/components/RNReactNativeRichTextEditorViewSpec/Props.h>

namespace facebook::react {

JSI_EXPORT extern const char ReactNativeRichTextEditorComponentName[];
/*
 * `ShadowNode` for <ReactNativeRichTextEditorComponentName> component.
 */
class ReactNativeRichTextEditorShadowNode final : public ConcreteViewShadowNode<
        ReactNativeRichTextEditorComponentName,
        ReactNativeRichTextEditorViewProps,
        ReactNativeRichTextEditorViewEventEmitter> {
public:
    using ConcreteViewShadowNode::ConcreteViewShadowNode;

    static ShadowNodeTraits BaseTraits() {
        auto traits = ConcreteViewShadowNode::BaseTraits();
        traits.set(ShadowNodeTraits::Trait::LeafYogaNode);
        traits.set(ShadowNodeTraits::Trait::MeasurableYogaNode);
        return traits;
    }

    // Associates a shared `RichTextEditorMeasurementManager` with the node.
    void setMeasurementsManager(
            const std::shared_ptr<RichTextEditorMeasurementManager>&
            measurementsManager);

    Size measureContent(
            const LayoutContext& layoutContext,
            const LayoutConstraints& layoutConstraints) const override;

private:
    std::shared_ptr<RichTextEditorMeasurementManager> measurementsManager_;
};
} // namespace facebook::react
