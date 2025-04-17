#import <React/RCTViewManager.h>
#import <React/RCTUIManager.h>
#import "RCTBridge.h"

@interface ReactNativeRichTextEditorViewManager : RCTViewManager
@end

@implementation ReactNativeRichTextEditorViewManager

RCT_EXPORT_MODULE(ReactNativeRichTextEditorView)

- (UIView *)view
{
  return [[UIView alloc] init];
}

RCT_EXPORT_VIEW_PROPERTY(color, NSString)

@end
