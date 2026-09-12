#import "EnrichedTextInputView.h"
#import "interfaces/StyleHeaders.h"

@implementation H3Style
+ (StyleType)getType {
  return H3;
}
- (NSString *)getValue {
  return @"EnrichedH3";
}
- (BOOL)isParagraph {
  return YES;
}
- (CGFloat)getHeadingFontSize {
  return [self.host.config h3FontSize];
}
- (BOOL)isHeadingBold {
  return [self.host.config h3Bold];
}
@end
