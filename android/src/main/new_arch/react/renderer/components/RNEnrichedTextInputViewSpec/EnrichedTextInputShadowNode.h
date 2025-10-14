#pragma once

#include "EnrichedTextInputMeasurementManager.h"
#include "EnrichedTextInputState.h"
#include "EnrichedTextInputProps.h"

#include <react/renderer/components/view/ConcreteViewShadowNode.h>
#include <react/renderer/components/RNEnrichedTextInputViewSpec/EventEmitters.h>

namespace facebook::react {

JSI_EXPORT extern const char EnrichedTextInputComponentName[];
/*
 * `ShadowNode` for <EnrichedTextInputView> component.
 */
class EnrichedTextInputShadowNode final : public ConcreteViewShadowNode<
        EnrichedTextInputComponentName,
        EnrichedTextInputProps,
        EnrichedTextInputViewEventEmitter,
        EnrichedTextInputState> {
public:
    using ConcreteViewShadowNode::ConcreteViewShadowNode;

    // This constructor is called when we "update" shadow node, e.g. after updating shadow node's state
    EnrichedTextInputShadowNode(
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

    // Associates a shared `EnrichedTextInputMeasurementManager` with the node.
    void setMeasurementsManager(
            const std::shared_ptr<EnrichedTextInputMeasurementManager>&
            measurementsManager);

    void dirtyLayoutIfNeeded();

    Size measureContent(
            const LayoutContext& layoutContext,
            const LayoutConstraints& layoutConstraints) const override;

private:
    int forceHeightRecalculationCounter_;
    std::shared_ptr<EnrichedTextInputMeasurementManager> measurementsManager_;
};
} // namespace facebook::react
