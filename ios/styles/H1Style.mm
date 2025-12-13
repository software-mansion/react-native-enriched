#import "EnrichedTextInputView.h"
#import "StyleHeaders.h"

@implementation H1Style
+ (StyleType)getStyleType {
  return H1;
}
+ (BOOL)isParagraphStyle {
  return YES;
}
+ (const char *)tagName {
  return "h1";
}
- (CGFloat)getHeadingFontSize {
  return [((EnrichedTextInputView *)input)->config h1FontSize];
}
- (BOOL)isHeadingBold {
  return [((EnrichedTextInputView *)input)->config h1Bold];
}
@end
