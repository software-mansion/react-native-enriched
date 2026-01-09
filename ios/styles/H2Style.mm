#import "EnrichedTextInputView.h"
#import "StyleHeaders.h"

@implementation H2Style
+ (StyleType)getStyleType {
  return H2;
}
+ (BOOL)isParagraphStyle {
  return YES;
}
- (CGFloat)getHeadingFontSize {
  CGFloat rawSize = [((EnrichedTextInputView *)input)->config h2FontSize];
  return [[UIFontMetrics defaultMetrics] scaledValueForValue:rawSize];
}
- (BOOL)isHeadingBold {
  return [((EnrichedTextInputView *)input)->config h2Bold];
}
@end
