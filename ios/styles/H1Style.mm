#import "EnrichedTextInputView.h"
#import "StyleHeaders.h"

@implementation H1Style
+ (StyleType)getStyleType {
  return H1;
}
+ (BOOL)isParagraphStyle {
  return YES;
}
- (CGFloat)getHeadingFontSize {
  CGFloat rawSize = [((EnrichedTextInputView *)input)->config h1FontSize];
  return [[UIFontMetrics defaultMetrics] scaledValueForValue:rawSize];
}
- (BOOL)isHeadingBold {
  return [((EnrichedTextInputView *)input)->config h1Bold];
}
@end
