#import "EnrichedTextViewShadowNode.h"
#import "CoreText/CoreText.h"
#import <EnrichedTextView.h>
#import <React/RCTShadowView+Layout.h>
#import <react/utils/ManagedObjectWrapper.h>

namespace facebook::react {

extern const char EnrichedTextViewComponentName[] = "EnrichedTextView";

id EnrichedTextViewShadowNode::setupMockTextView_() const {
  const int veryFarAway = 20000;
  const int mockSize = 1000;
  EnrichedTextView *mockView = [[EnrichedTextView alloc]
      initWithFrame:(CGRectMake(veryFarAway, veryFarAway, mockSize, mockSize))];
  const auto props = this->getProps();
  [mockView updateProps:props oldProps:nullptr];
  return mockView;
}

Size EnrichedTextViewShadowNode::measureContent(
    const LayoutContext &layoutContext,
    const LayoutConstraints &layoutConstraints) const {
  const auto state = this->getStateData();
  const auto componentRef = state.getComponentViewRef();
  RCTInternalGenericWeakWrapper *weakWrapper =
      (RCTInternalGenericWeakWrapper *)unwrapManagedObject(componentRef);

  if (weakWrapper != nullptr) {
    id componentObject = weakWrapper.object;
    EnrichedTextView *typedComponentObject =
        (EnrichedTextView *)componentObject;

    if (typedComponentObject != nullptr) {
      __block CGSize estimatedSize;

      if ([NSThread isMainThread]) {
        estimatedSize = [typedComponentObject
            measureSize:layoutConstraints.maximumSize.width];
      } else {
        dispatch_sync(dispatch_get_main_queue(), ^{
          estimatedSize = [typedComponentObject
              measureSize:layoutConstraints.maximumSize.width];
        });
      }

      return {estimatedSize.width,
              MIN(estimatedSize.height, layoutConstraints.maximumSize.height)};
    }
  } else {
    __block CGSize estimatedSize;

    if ([NSThread isMainThread]) {
      EnrichedTextView *mockView = setupMockTextView_();
      estimatedSize =
          [mockView measureSize:layoutConstraints.maximumSize.width];
    } else {
      dispatch_sync(dispatch_get_main_queue(), ^{
        EnrichedTextView *mockView = setupMockTextView_();
        estimatedSize =
            [mockView measureSize:layoutConstraints.maximumSize.width];
      });
    }

    return {estimatedSize.width,
            MIN(estimatedSize.height, layoutConstraints.maximumSize.height)};
  }

  return Size();
}

} // namespace facebook::react
