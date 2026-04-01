#import "EnrichedTextInputView.h"
#import "StyleHeaders.h"

@implementation H4Style
+ (StyleType)getType {
  return H4;
}
- (NSString *)getValue {
  return @"EnrichedH4";
}
- (BOOL)isParagraph {
  return YES;
}
- (CGFloat)getHeadingFontSize {
  return [self.input->config h4FontSize];
}
- (BOOL)isHeadingBold {
  return [self.input->config h4Bold];
}
@end
