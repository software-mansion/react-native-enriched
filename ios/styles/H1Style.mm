#import "StyleHeaders.h"
#import "ReactNativeRichTextEditorView.h"

@implementation H1Style
+ (StyleType)getStyleType { return H1; }
- (CGFloat)getHeadingFontSize { return [((ReactNativeRichTextEditorView *)editor)->config h1FontSize]; }
- (BOOL)isHeadingBold {
  return [((ReactNativeRichTextEditorView *)editor)->config h1Bold];
}
@end
