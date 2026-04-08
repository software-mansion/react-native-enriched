#import "EnrichedTextInputView.h"
#import "StyleHeaders.h"

@implementation H1Style
+ (StyleType)getType {
  return H1;
}
- (NSString *)getValue {
  return @"EnrichedH1";
}
- (BOOL)isParagraph {
  return YES;
}
- (CGFloat)getHeadingFontSize {
  return [self.host.config h1FontSize];
}
- (BOOL)isHeadingBold {
  return [self.host.config h1Bold];
}
@end
