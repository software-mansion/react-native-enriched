#import "EnrichedTextInputView.h"
#import "StyleHeaders.h"

@implementation H6Style
+ (StyleType)getType {
  return H6;
}
- (NSString *)getValue {
  return @"EnrichedH6";
}
- (BOOL)isParagraph {
  return YES;
}
- (CGFloat)getHeadingFontSize {
  return [self.input->config h6FontSize];
}
- (BOOL)isHeadingBold {
  return [self.input->config h6Bold];
}
@end
