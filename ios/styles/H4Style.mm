#import "StyleHeaders.h"
#import "EnrichedTextInputView.h"

@implementation H4Style
+ (StyleType)getStyleType { return H4; }
- (CGFloat)getHeadingFontSize { return [((EnrichedTextInputView *)input)->config h4FontSize]; }
- (BOOL)isHeadingBold {
  return [((EnrichedTextInputView *)input)->config h4Bold];
}
@end
