#import "StyleHeaders.h"
#import "EnrichedTextInputView.h"

@implementation H5Style
+ (StyleType)getStyleType { return H5; }
- (CGFloat)getHeadingFontSize { return [((EnrichedTextInputView *)input)->config h5FontSize]; }
- (BOOL)isHeadingBold {
  return [((EnrichedTextInputView *)input)->config h5Bold];
}
@end
