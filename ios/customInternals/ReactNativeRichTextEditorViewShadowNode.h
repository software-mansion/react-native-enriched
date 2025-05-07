#pragma once
#include <ReactNativeRichTextEditor/EventEmitters.h>
#include <ReactNativeRichTextEditor/Props.h>
#include <ReactNativeRichTextEditor/ReactNativeRichTextEditorViewState.h>
#include <react/renderer/components/view/ConcreteViewShadowNode.h>
#include <react/renderer/core/LayoutConstraints.h>
#include <jsi/jsi.h>

namespace facebook::react {

JSI_EXPORT extern const char ReactNativeRichTextEditorViewComponentName[];

/*
 * `ShadowNode` for <ReactNativeRichTextEditorView> component.
 */
class ReactNativeRichTextEditorViewShadowNode : public ConcreteViewShadowNode<
        ReactNativeRichTextEditorViewComponentName,
        ReactNativeRichTextEditorViewProps,
        ReactNativeRichTextEditorViewEventEmitter,
        ReactNativeRichTextEditorViewState> {
    public:
    using ConcreteViewShadowNode::ConcreteViewShadowNode;
    ReactNativeRichTextEditorViewShadowNode(const ShadowNodeFragment& fragment, const ShadowNodeFamily::Shared& family, ShadowNodeTraits traits);
    ReactNativeRichTextEditorViewShadowNode(const ShadowNode& sourceShadowNode, const ShadowNodeFragment& fragment);
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
