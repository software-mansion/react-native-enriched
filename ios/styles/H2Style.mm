#import "StyleHeaders.h"
#import "EnrichedTextInputView.h"

@implementation H2Style
+ (StyleType)getStyleType { return H2; }
- (CGFloat)getHeadingFontSize { return [((EnrichedTextInputView *)input)->config h2FontSize]; }
- (BOOL)isHeadingBold {
  return [((EnrichedTextInputView *)input)->config h2Bold];
}
@end
