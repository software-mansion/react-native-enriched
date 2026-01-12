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
  return [((EnrichedTextInputView *)input)->config h2FontSize];
}
- (BOOL)isHeadingBold {
  return [((EnrichedTextInputView *)input)->config h2Bold];
}
@end
