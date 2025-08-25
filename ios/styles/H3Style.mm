#import "StyleHeaders.h"
#import "ReactNativeRichTextEditorView.h"

@implementation H3Style
+ (StyleType)getStyleType { return H3; }
- (CGFloat)getHeadingFontSize { return [((ReactNativeRichTextEditorView *)editor)->config h3FontSize]; }
- (BOOL)isHeadingBold {
  return [((ReactNativeRichTextEditorView *)editor)->config h3Bold];
}
@end
