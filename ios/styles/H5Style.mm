#import "EnrichedTextInputView.h"
#import "StyleHeaders.h"

@implementation H5Style
+ (StyleType)getStyleType {
  return H5;
}
+ (BOOL)isParagraphStyle {
  return YES;
}
+ (const char *)tagName {
  return "h5";
}
- (CGFloat)getHeadingFontSize {
  return [((EnrichedTextInputView *)input)->config h5FontSize];
}
- (BOOL)isHeadingBold {
  return [((EnrichedTextInputView *)input)->config h5Bold];
}
@end
