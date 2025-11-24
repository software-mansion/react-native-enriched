#import "EnrichedTextInputViewShadowNode.h"
#import <EnrichedTextInputView.h>
#import <react/utils/ManagedObjectWrapper.h>
#import <yoga/Yoga.h>
#import <React/RCTShadowView+Layout.h>
#import "CoreText/CoreText.h"

namespace facebook::react {

extern const char EnrichedTextInputViewComponentName[] = "EnrichedTextInputView";
id EnrichedTextInputViewShadowNode::mockTextInputView_ = nullptr;

EnrichedTextInputViewShadowNode::EnrichedTextInputViewShadowNode(
  const ShadowNodeFragment& fragment,
  const ShadowNodeFamily::Shared& family,
  ShadowNodeTraits traits
): ConcreteViewShadowNode(fragment, family, traits) {
  localForceHeightRecalculationCounter_ = 0;
  
  // mock text input needs to be initialized on the main thread
  if([NSThread isMainThread]) {
    setupMockTextInputView_();
  } else {
    dispatch_sync(dispatch_get_main_queue(), ^{
      setupMockTextInputView_();
    });
  }
}

// mock input is used for the first measure calls that need to be done when the real input isn't defined yet
void EnrichedTextInputViewShadowNode::setupMockTextInputView_() {
  // it's rendered far away from the viewport
  const int veryFarAway = 20000;
  const int mockSize = 1000;
  mockTextInputView_ = [[EnrichedTextInputView alloc] initWithFrame:(CGRectMake(veryFarAway, veryFarAway, mockSize, mockSize))];
  const auto props = this->getProps();
  ((EnrichedTextInputView *)mockTextInputView_)->blockEmitting = YES;
  [mockTextInputView_ updateProps:props oldProps:nullptr];
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
      // remove the mock input on the first render with a defined real input
      if(mockTextInputView_ != nullptr) {
        mockTextInputView_ = nullptr;
      }
    
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
    if(mockTextInputView_ == nullptr) {
      return Size();
    }
  
    __block CGSize estimatedSize;
      
    // synchronously dispatch to main thread if needed
    if([NSThread isMainThread]) {
      estimatedSize = [mockTextInputView_ measureSize:layoutConstraints.maximumSize.width];
    } else {
      dispatch_sync(dispatch_get_main_queue(), ^{
        estimatedSize = [mockTextInputView_ measureSize:layoutConstraints.maximumSize.width];
      });
    }

    return {
      estimatedSize.width,
      MIN(estimatedSize.height, layoutConstraints.maximumSize.height)
    };
  }
  
  return Size();
}
 
} // namespace facebook::react
