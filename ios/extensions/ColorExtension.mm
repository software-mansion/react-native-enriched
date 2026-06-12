#import "ColorExtension.h"

@implementation UIColor (ColorExtension)
- (BOOL)isEqualToColor:(UIColor *)otherColor {
  CGColorSpaceRef colorSpaceRGB = CGColorSpaceCreateDeviceRGB();

  UIColor * (^convertColorToRGBSpace)(UIColor *) = ^(UIColor *color) {
    if (CGColorSpaceGetModel(CGColorGetColorSpace(color.CGColor)) ==
        kCGColorSpaceModelMonochrome) {
      const CGFloat *oldComponents = CGColorGetComponents(color.CGColor);
      CGFloat components[4] = {oldComponents[0], oldComponents[0],
                               oldComponents[0], oldComponents[1]};
      CGColorRef colorRef = CGColorCreate(colorSpaceRGB, components);

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

// Default fallback alpha of 0.4 — opaque colors get this applied so the text
// cursor remains visible through the highlight. If the caller already set a
// custom alpha (anything below 1.0), we respect that value instead.
- (UIColor *)colorWithResolvedAlpha {
  return [self colorWithResolvedAlpha:0.4];
}

- (UIColor *)colorWithResolvedAlpha:(CGFloat)newAlpha {
  CGFloat alpha = 0.0;
  [self getRed:nil green:nil blue:nil alpha:&alpha];
  // alpha == 1.0 means the color was never given a custom transparency, so
  // apply newAlpha. Any other value means the caller explicitly chose it —
  // leave it untouched.
  if (alpha >= 1.0) {
    return [self colorWithAlphaComponent:newAlpha];
  }
  return self;
}
@end
