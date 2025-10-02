#import "EnrichedTextInputViewShadowNode.h"
#import <EnrichedTextInputView.h>
#import <react/utils/ManagedObjectWrapper.h>
#import <yoga/Yoga.h>
#import <React/RCTShadowView+Layout.h>
#import "CoreText/CoreText.h"

namespace facebook::react {

extern const char EnrichedTextInputViewComponentName[] = "EnrichedTextInputView";

EnrichedTextInputViewShadowNode::EnrichedTextInputViewShadowNode(
  const ShadowNodeFragment& fragment,
  const ShadowNodeFamily::Shared& family,
  ShadowNodeTraits traits
): ConcreteViewShadowNode(fragment, family, traits) {
  localForceHeightRecalculationCounter_ = 0;
}

EnrichedTextInputViewShadowNode::EnrichedTextInputViewShadowNode(
  const ShadowNode& sourceShadowNode,
  const ShadowNodeFragment& fragment
): ConcreteViewShadowNode(sourceShadowNode, fragment) {
  dirtyLayoutIfNeeded();
}

void EnrichedTextInputViewShadowNode::dirtyLayoutIfNeeded() {
  const auto state = this->getStateData();
  const int receivedCounter = state.getForceHeightRecalculationCounter();
  
  if(receivedCounter > localForceHeightRecalculationCounter_) {
    localForceHeightRecalculationCounter_ = receivedCounter;
    YGNodeMarkDirty(&yogaNode_);
  }
}

Size EnrichedTextInputViewShadowNode::measureContent(const LayoutContext& layoutContext, const LayoutConstraints& layoutConstraints) const {
  const auto state = this->getStateData();
  const auto componentRef = state.getComponentViewRef();
  RCTInternalGenericWeakWrapper *weakWrapper = (RCTInternalGenericWeakWrapper *)unwrapManagedObject(componentRef);
  
  if(weakWrapper != nullptr) {
    id componentObject = weakWrapper.object;
    EnrichedTextInputView *typedComponentObject = (EnrichedTextInputView *) componentObject;
    
    if(typedComponentObject != nullptr) {
      __block CGSize estimatedSize;
      
      // synchronously dispatch to main thread if needed
      if([NSThread isMainThread]) {
        estimatedSize = [typedComponentObject measureSize:layoutConstraints.maximumSize.width];
      } else {
        dispatch_sync(dispatch_get_main_queue(), ^{
          estimatedSize = [typedComponentObject measureSize:layoutConstraints.maximumSize.width];
        });
      }
      
      return {
        estimatedSize.width,
        MIN(estimatedSize.height, layoutConstraints.maximumSize.height)
      };
    }
  } else {
    // on the very first call there is no componentView that we can query for the component height
    // thus, a little heuristic: just put a height that is exactly height of letter "I" with default apple font and size from props
    // in a lot of cases it will be the desired height
    // in others, the jump on the second call will at least be smaller
    const auto props = this->getProps();
    const auto &typedProps = *std::static_pointer_cast<EnrichedTextInputViewProps const>(props);
    NSAttributedString *attrStr = [[NSAttributedString alloc] initWithString:@"I" attributes:@{NSFontAttributeName: [UIFont systemFontOfSize:typedProps.fontSize]}];
    CTFramesetterRef framesetter = CTFramesetterCreateWithAttributedString((CFAttributedStringRef)attrStr);
    const CGSize &suggestedSize = CTFramesetterSuggestFrameSizeWithConstraints(
      framesetter,
      CFRangeMake(0, 1),
      nullptr,
      CGSizeMake(layoutConstraints.maximumSize.width, DBL_MAX),
      nullptr
    );
    
    return {suggestedSize.width, suggestedSize.height};
  }
  
  return Size();
}
 
} // namespace facebook::react
