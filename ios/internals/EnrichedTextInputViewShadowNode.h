#pragma once
#include <ReactNativeEnriched/EnrichedTextInputViewState.h>
#include <ReactNativeEnriched/EventEmitters.h>
#include <ReactNativeEnriched/Props.h>
#include <jsi/jsi.h>
#include <react/renderer/components/view/ConcreteViewShadowNode.h>
#include <react/renderer/core/LayoutConstraints.h>

namespace facebook::react {

JSI_EXPORT extern const char EnrichedTextInputViewComponentName[];

/*
 * `ShadowNode` for <EnrichedTextInputView> component.
 */
class EnrichedTextInputViewShadowNode
    : public ConcreteViewShadowNode<
          EnrichedTextInputViewComponentName, EnrichedTextInputViewProps,
          EnrichedTextInputViewEventEmitter, EnrichedTextInputViewState> {

public:
  using ConcreteViewShadowNode::ConcreteViewShadowNode;
  EnrichedTextInputViewShadowNode(const ShadowNodeFragment &fragment,
                                  const ShadowNodeFamily::Shared &family,
                                  ShadowNodeTraits traits);
  EnrichedTextInputViewShadowNode(const ShadowNode &sourceShadowNode,
                                  const ShadowNodeFragment &fragment);
  void dirtyLayoutIfNeeded();

  Size
  measureContent(const LayoutContext &layoutContext,
                 const LayoutConstraints &layoutConstraints) const override;

  static ShadowNodeTraits BaseTraits() {
    auto traits = ConcreteViewShadowNode::BaseTraits();
    traits.set(ShadowNodeTraits::Trait::LeafYogaNode);
    traits.set(ShadowNodeTraits::Trait::MeasurableYogaNode);
    return traits;
  }

private:
  mutable Size _prevContentSize{NAN, NAN};
  id setupMockTextInputView_() const;
};

} // namespace facebook::react
