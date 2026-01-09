#import "EnrichedTextInputView.h"
#import "StyleHeaders.h"

@implementation H4Style
+ (StyleType)getStyleType {
  return H4;
}
+ (BOOL)isParagraphStyle {
  return YES;
}
+ (const char *)tagName {
  return "h4";
}
- (CGFloat)getHeadingFontSize {
  return [((EnrichedTextInputView *)input)->config h4FontSize];
}
- (BOOL)isHeadingBold {
  return [((EnrichedTextInputView *)input)->config h4Bold];
}
@end
