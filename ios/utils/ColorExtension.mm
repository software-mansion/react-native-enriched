#import "ColorExtension.h"

@implementation UIColor (ColorExtension)
- (BOOL)isEqualToColor:(UIColor *)otherColor {
  CGColorSpaceRef colorSpaceRGB = CGColorSpaceCreateDeviceRGB();

  UIColor *(^convertColorToRGBSpace)(UIColor*) = ^(UIColor *color) {
    if(CGColorSpaceGetModel(CGColorGetColorSpace(color.CGColor)) == kCGColorSpaceModelMonochrome) {
      const CGFloat *oldComponents = CGColorGetComponents(color.CGColor);
      CGFloat components[4] = {oldComponents[0], oldComponents[0], oldComponents[0], oldComponents[1]};
      CGColorRef colorRef = CGColorCreate( colorSpaceRGB, components );

      UIColor *color = [UIColor colorWithCGColor:colorRef];
      CGColorRelease(colorRef);
      return color;
    } else {
      return color;
    }
  };

  UIColor *selfColor = convertColorToRGBSpace(self);
  otherColor = convertColorToRGBSpace(otherColor);
  CGColorSpaceRelease(colorSpaceRGB);

  return [selfColor isEqual:otherColor];
}

- (UIColor *)colorWithAlphaIfNotTransparent:(CGFloat)newAlpha {
  CGFloat alpha = 0.0;
  [self getRed:nil green:nil blue:nil alpha:&alpha];
  if (alpha > 0.0) {
      return [self colorWithAlphaComponent:newAlpha];
  }
  return self;
}
@end
