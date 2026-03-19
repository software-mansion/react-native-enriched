#import "EnrichedTextInputView.h"
#import "StyleHeaders.h"

@implementation H3Style
+ (StyleType)getType {
  return H3;
}
- (NSString *)getValue {
  return @"h3";
}
- (BOOL)isParagraph {
  return YES;
}
- (CGFloat)getHeadingFontSize {
  return [self.input->config h3FontSize];
}
- (BOOL)isHeadingBold {
  return [self.input->config h3Bold];
}
@end
