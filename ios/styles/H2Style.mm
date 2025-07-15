#import "StyleHeaders.h"
#import "ReactNativeRichTextEditorView.h"

@implementation H2Style
+ (StyleType)getStyleType { return H2; }
- (CGFloat)getHeadingFontSize { return [((ReactNativeRichTextEditorView *)editor)->config h2FontSize]; }
@end
