#import <React/RCTUIManager.h>
#import <React/RCTViewManager.h>

@interface EnrichedTextInputViewManager : RCTViewManager
@end

@implementation EnrichedTextInputViewManager

RCT_EXPORT_MODULE(EnrichedTextInputView)

RCT_EXPORT_VIEW_PROPERTY(defaultValue, NSString)

@end
