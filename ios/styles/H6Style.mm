#import "EnrichedTextInputView.h"
#import "StyleHeaders.h"

@implementation H6Style
+ (StyleType)getStyleType {
  return H6;
}
+ (BOOL)isParagraphStyle {
  return YES;
}
+ (const char *)tagName {
  return "h6";
}
- (CGFloat)getHeadingFontSize {
  return [((EnrichedTextInputView *)input)->config h6FontSize];
}
- (BOOL)isHeadingBold {
  return [((EnrichedTextInputView *)input)->config h6Bold];
}
@end
