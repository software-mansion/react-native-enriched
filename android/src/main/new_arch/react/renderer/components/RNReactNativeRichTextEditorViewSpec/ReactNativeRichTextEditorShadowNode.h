#pragma once

#include "RichTextEditorMeasurementManager.h"
#include "ReactNativeRichTextEditorViewState.h"

#include <react/renderer/components/view/ConcreteViewShadowNode.h>
#include <react/renderer/components/RNReactNativeRichTextEditorViewSpec/Props.h>
#include <react/renderer/components/RNReactNativeRichTextEditorViewSpec/EventEmitters.h>

namespace facebook::react {

JSI_EXPORT extern const char ReactNativeRichTextEditorComponentName[];
/*
 * `ShadowNode` for <ReactNativeRichTextEditorComponentName> component.
 */
class ReactNativeRichTextEditorShadowNode final : public ConcreteViewShadowNode<
        ReactNativeRichTextEditorComponentName,
        ReactNativeRichTextEditorViewProps,
        ReactNativeRichTextEditorViewEventEmitter,
        ReactNativeRichTextEditorViewState> {
public:
    using ConcreteViewShadowNode::ConcreteViewShadowNode;

    // This constructor is called when we "update" shadow node, e.g. after updating shadow node's state
    ReactNativeRichTextEditorShadowNode(
            ShadowNode const &sourceShadowNode,
            ShadowNodeFragment const &fragment)
        : ConcreteViewShadowNode(sourceShadowNode, fragment) {
            dirtyLayoutIfNeeded();
    }

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

    void dirtyLayoutIfNeeded();

    Size measureContent(
            const LayoutContext& layoutContext,
            const LayoutConstraints& layoutConstraints) const override;

private:
    int forceHeightRecalculationCounter_;
    std::shared_ptr<RichTextEditorMeasurementManager> measurementsManager_;
};
} // namespace facebook::react
