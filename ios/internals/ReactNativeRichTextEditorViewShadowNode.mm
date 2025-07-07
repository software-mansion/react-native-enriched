#import "ReactNativeRichTextEditorViewShadowNode.h"
#import <ReactNativeRichTextEditorView.h>
#import <react/utils/ManagedObjectWrapper.h>
#import <yoga/Yoga.h>
#import <React/RCTShadowView+Layout.h>

namespace facebook::react {

extern const char ReactNativeRichTextEditorViewComponentName[] = "ReactNativeRichTextEditorView";

ReactNativeRichTextEditorViewShadowNode::ReactNativeRichTextEditorViewShadowNode(
  const ShadowNodeFragment& fragment,
  const ShadowNodeFamily::Shared& family,
  ShadowNodeTraits traits
): ConcreteViewShadowNode(fragment, family, traits) {
  localForceHeightRecalculationCounter_ = 0;
}

ReactNativeRichTextEditorViewShadowNode::ReactNativeRichTextEditorViewShadowNode(
  const ShadowNode& sourceShadowNode,
  const ShadowNodeFragment& fragment
): ConcreteViewShadowNode(sourceShadowNode, fragment) {
  dirtyLayoutIfNeeded();
}

void ReactNativeRichTextEditorViewShadowNode::dirtyLayoutIfNeeded() {
  const auto state = this->getStateData();
  const int receivedCounter = state.getForceHeightRecalculationCounter();
  
  if(receivedCounter > localForceHeightRecalculationCounter_) {
    localForceHeightRecalculationCounter_ = receivedCounter;
    YGNodeMarkDirty(&yogaNode_);
  }
}

Size ReactNativeRichTextEditorViewShadowNode::measureContent(const LayoutContext& layoutContext, const LayoutConstraints& layoutConstraints) const {
  const auto state = this->getStateData();
  const auto componentRef = state.getComponentViewRef();
  RCTInternalGenericWeakWrapper *weakWrapper = (RCTInternalGenericWeakWrapper *)unwrapManagedObject(componentRef);
  
  if(weakWrapper != nullptr) {
    id componentObject = weakWrapper.object;
    ReactNativeRichTextEditorView *typedComponentObject = (ReactNativeRichTextEditorView *) componentObject;
    
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
      
      return {estimatedSize.width, estimatedSize.height};
    }
  }
  
  return Size();
}
 
} // namespace facebook::react
