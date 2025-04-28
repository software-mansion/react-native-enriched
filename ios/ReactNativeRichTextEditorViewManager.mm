#import <React/RCTLog.h>
#import <React/RCTUIManager.h>
#import <React/RCTViewManager.h>
#import "ReactNativeRichTextEditorView.h"

@interface ReactNativeRichTextEditorViewManager : RCTViewManager
@end

@implementation ReactNativeRichTextEditorViewManager

RCT_EXPORT_MODULE(ReactNativeRichTextEditorView)

RCT_EXPORT_VIEW_PROPERTY(defaultValue, NSString)

- (UIView *)view
{
  return [[ReactNativeRichTextEditorView alloc] init];
}

@end
