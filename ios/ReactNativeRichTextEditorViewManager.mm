#import <React/RCTUIManager.h>
#import <React/RCTViewManager.h>

@interface ReactNativeRichTextEditorViewManager : RCTViewManager
@end

@implementation ReactNativeRichTextEditorViewManager

RCT_EXPORT_MODULE(ReactNativeRichTextEditorView)

RCT_EXPORT_VIEW_PROPERTY(defaultValue, NSString)

@end
