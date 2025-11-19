#import "StyleHeaders.h"
#import "EnrichedTextInputView.h"

@implementation H1Style
+ (StyleType)getStyleType { return H1; }
+ (BOOL)isParagraphStyle { return NO; }
- (CGFloat)getHeadingFontSize { return [((EnrichedTextInputView *)input)->config h1FontSize]; }
- (BOOL)isHeadingBold {
  return [((EnrichedTextInputView *)input)->config h1Bold];
}
@end
