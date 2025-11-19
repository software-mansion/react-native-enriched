#import "StyleHeaders.h"
#import "EnrichedTextInputView.h"

@implementation H3Style
+ (StyleType)getStyleType { return H3; }
+ (BOOL)isParagraphStyle { return NO; }
- (CGFloat)getHeadingFontSize { return [((EnrichedTextInputView *)input)->config h3FontSize]; }
- (BOOL)isHeadingBold {
  return [((EnrichedTextInputView *)input)->config h3Bold];
}
@end
