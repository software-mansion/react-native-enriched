#import "StyleHeaders.h"
#import "ReactNativeRichTextEditorView.h"

@implementation H3Style
+ (StyleType)getStyleType { return H3; }
- (CGFloat)getHeadingFontSize { return [((ReactNativeRichTextEditorView *)editor)->config h3FontSize]; }
@end
