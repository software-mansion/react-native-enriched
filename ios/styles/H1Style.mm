#import "EnrichedTextInputView.h"
#import "StyleHeaders.h"

@implementation H1Style
+ (StyleType)getType {
  return H1;
}
- (NSString *)getValue {
  return @"h1";
}
- (BOOL)isParagraph {
  return YES;
}
- (CGFloat)getHeadingFontSize {
  return [self.input->config h1FontSize];
}
- (BOOL)isHeadingBold {
  return [self.input->config h1Bold];
}
@end
