#import "EnrichedTextInputView.h"
#import "StyleHeaders.h"

@implementation H4Style
+ (StyleType)getStyleType {
  return H4;
}
+ (BOOL)isParagraphStyle {
  return YES;
}
- (CGFloat)getHeadingFontSize {
  CGFloat rawSize = [((EnrichedTextInputView *)input)->config h4FontSize];
  return [[UIFontMetrics defaultMetrics] scaledValueForValue:rawSize];
}
- (BOOL)isHeadingBold {
  return [((EnrichedTextInputView *)input)->config h4Bold];
}
@end
