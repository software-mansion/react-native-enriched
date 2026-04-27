#import "EnrichedTextInputView.h"
#import "StyleHeaders.h"

@implementation H5Style
+ (StyleType)getType {
  return H5;
}
- (NSString *)getValue {
  return @"EnrichedH5";
}
- (BOOL)isParagraph {
  return YES;
}
- (CGFloat)getHeadingFontSize {
  return [self.host.config h5FontSize];
}
- (BOOL)isHeadingBold {
  return [self.host.config h5Bold];
}
@end
