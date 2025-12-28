#import "EnrichedTextInputViewShadowNode.h"

#import <EnrichedTextInputView.h>
#import <React/RCTShadowView+Layout.h>
#import <react/utils/ManagedObjectWrapper.h>
#import <yoga/Yoga.h>

namespace facebook::react {

extern const char EnrichedTextInputViewComponentName[] =
    "EnrichedTextInputView";

void EnrichedTextInputViewShadowNode::dirtyLayoutIfNeeded() {
  const auto &state = getStateData();
  const auto nextSize = state.getContentSize();

  if (_prevContentSize != nextSize) {
    YGNodeMarkDirty(&yogaNode_);
  }

  _prevContentSize = nextSize;
}

id EnrichedTextInputViewShadowNode::setupMockTextInputView_() const {
  // it's rendered far away from the viewport
  const int veryFarAway = 20000;
  const int mockSize = 1000;
  EnrichedTextInputView *mockTextInputView_ = [[EnrichedTextInputView alloc]
      initWithFrame:(CGRectMake(veryFarAway, veryFarAway, mockSize, mockSize))];
  const auto props = this->getProps();
  mockTextInputView_->blockEmitting = YES;
  [mockTextInputView_ updateProps:props oldProps:nullptr];
  return mockTextInputView_;
}

EnrichedTextInputViewShadowNode::EnrichedTextInputViewShadowNode(
    const ShadowNode &source, const ShadowNodeFragment &fragment)
    : ConcreteViewShadowNode(source, fragment) {

  const auto &oldState =
      static_cast<const EnrichedTextInputViewShadowNode &>(source)
          .getStateData();

  const auto &newState = getStateData();

  const auto &oldSize = oldState.getContentSize();
  const auto &newSize = newState.getContentSize();

  if (newSize != oldSize) {
    YGNodeMarkDirty(&yogaNode_);
  }
}

EnrichedTextInputViewShadowNode::EnrichedTextInputViewShadowNode(
    const ShadowNodeFragment &fragment, const ShadowNodeFamily::Shared &family,
    ShadowNodeTraits traits)
    : ConcreteViewShadowNode(fragment, family, traits) {
  _prevContentSize = {};
}

Size EnrichedTextInputViewShadowNode::measureContent(
    const LayoutContext &, const LayoutConstraints &constraints) const {
  const auto state = this->getStateData();
  const auto componentRef = state.getComponentViewRef();
  RCTInternalGenericWeakWrapper *weakWrapper =
      (RCTInternalGenericWeakWrapper *)unwrapManagedObject(componentRef);
  if (weakWrapper != nullptr) {
    id componentObject = weakWrapper.object;
    EnrichedTextInputView *typedComponentObject =
        (EnrichedTextInputView *)componentObject;

    if (typedComponentObject != nullptr) {
      auto size = state.getContentSize();
      _prevContentSize = size;
      return constraints.clamp(size);
    }
  } else {
    __block CGSize estimatedSize;
    // synchronously dispatch to main thread if needed
    if ([NSThread isMainThread]) {
      EnrichedTextInputView *mockTextInputView = setupMockTextInputView_();
      estimatedSize = [mockTextInputView
          measureInitialSizeWithMaxWidth:constraints.maximumSize.width];
    } else {
      dispatch_sync(dispatch_get_main_queue(), ^{
        EnrichedTextInputView *mockTextInputView = setupMockTextInputView_();
        estimatedSize = [mockTextInputView
            measureInitialSizeWithMaxWidth:constraints.maximumSize.width];
      });
    }

    return {estimatedSize.width,
            MIN(estimatedSize.height, constraints.maximumSize.height)};
  }

  return Size();
}

} // namespace facebook::react
