#import "EnrichedTextInputView.h"
#import "StyleHeaders.h"

@implementation H2Style
+ (StyleType)getType {
  return H2;
}
- (NSString *)getValue {
  return @"EnrichedH2";
}
- (BOOL)isParagraph {
  return YES;
}
- (CGFloat)getHeadingFontSize {
  return [self.host.config h2FontSize];
}
- (BOOL)isHeadingBold {
  return [self.host.config h2Bold];
}
@end
