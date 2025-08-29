#pragma once
#include <ReactNativeEnriched/EventEmitters.h>
#include <ReactNativeEnriched/Props.h>
#include <ReactNativeEnriched/EnrichedTextInputViewState.h>
#include <react/renderer/components/view/ConcreteViewShadowNode.h>
#include <react/renderer/core/LayoutConstraints.h>
#include <jsi/jsi.h>

namespace facebook::react {

JSI_EXPORT extern const char EnrichedTextInputViewComponentName[];

/*
 * `ShadowNode` for <EnrichedTextInputView> component.
 */
class EnrichedTextInputViewShadowNode : public ConcreteViewShadowNode<
        EnrichedTextInputViewComponentName,
        EnrichedTextInputViewProps,
        EnrichedTextInputViewEventEmitter,
        EnrichedTextInputViewState> {
    public:
    using ConcreteViewShadowNode::ConcreteViewShadowNode;
    EnrichedTextInputViewShadowNode(const ShadowNodeFragment& fragment, const ShadowNodeFamily::Shared& family, ShadowNodeTraits traits);
    EnrichedTextInputViewShadowNode(const ShadowNode& sourceShadowNode, const ShadowNodeFragment& fragment);
    void dirtyLayoutIfNeeded();
    Size measureContent(const LayoutContext& layoutContext, const LayoutConstraints& layoutConstraints) const override;
    
    
    static ShadowNodeTraits BaseTraits() {
      auto traits = ConcreteViewShadowNode::BaseTraits();
      traits.set(ShadowNodeTraits::Trait::LeafYogaNode);
      traits.set(ShadowNodeTraits::Trait::MeasurableYogaNode);
      return traits;
    }
    
    private:
    int localForceHeightRecalculationCounter_;
};

} // namespace facebook::react
