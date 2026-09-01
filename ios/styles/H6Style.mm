#import "EnrichedTextInputView.h"
#import "interfaces/StyleHeaders.h"

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
  return [self.host.config h6FontSize];
}
- (BOOL)isHeadingBold {
  return [self.host.config h6Bold];
}
@end
