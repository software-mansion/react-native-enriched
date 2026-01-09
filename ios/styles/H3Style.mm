#import "EnrichedTextInputView.h"
#import "StyleHeaders.h"

@implementation H3Style
+ (StyleType)getStyleType {
  return H3;
}
+ (BOOL)isParagraphStyle {
  return YES;
}
- (CGFloat)getHeadingFontSize {
  CGFloat rawSize = [((EnrichedTextInputView *)input)->config h3FontSize];
  return [[UIFontMetrics defaultMetrics] scaledValueForValue:rawSize];
}
- (BOOL)isHeadingBold {
  return [((EnrichedTextInputView *)input)->config h3Bold];
}
@end
