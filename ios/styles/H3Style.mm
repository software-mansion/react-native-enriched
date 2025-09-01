#import "StyleHeaders.h"
#import "EnrichedTextInputView.h"

@implementation H3Style
+ (StyleType)getStyleType { return H3; }
- (CGFloat)getHeadingFontSize { return [((EnrichedTextInputView *)input)->config h3FontSize]; }
- (BOOL)isHeadingBold {
  return [((EnrichedTextInputView *)input)->config h3Bold];
}
@end
