#import <React/RCTUIManager.h>
#import <React/RCTViewManager.h>

@interface EnrichedTextViewManager : RCTViewManager
@end

@implementation EnrichedTextViewManager

RCT_EXPORT_MODULE(EnrichedTextView)

RCT_EXPORT_VIEW_PROPERTY(text, NSString)

@end
