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

- (UIColor *)colorWithAlphaIfNotTransparent:(CGFloat)newAlpha {
  CGFloat alpha = 0.0;
  [self getRed:nil green:nil blue:nil alpha:&alpha];
  if (alpha > 0.0) {
    return [self colorWithAlphaComponent:newAlpha];
  }
  return self;
}
@end

@implementation UIColor (FromString)
+ (UIColor *)colorFromString:(NSString *)string {
    if (!string) return nil;
    
    NSString *input = [[string stringByTrimmingCharactersInSet:[NSCharacterSet whitespaceAndNewlineCharacterSet]] lowercaseString];
    
    // Expanded named colors (add more from CSS list as needed)
    NSDictionary *namedColors = @{
        @"red": [UIColor redColor],
        @"green": [UIColor greenColor],
        @"blue": [UIColor blueColor],
        @"black": [UIColor blackColor],
        @"white": [UIColor whiteColor],
        @"yellow": [UIColor yellowColor],
        @"gray": [UIColor grayColor],
        @"grey": [UIColor grayColor],
        @"transparent": [UIColor clearColor],
        @"aliceblue": [UIColor colorWithRed:0.941 green:0.973 blue:1.0 alpha:1.0],
        // Add additional CSS names here, e.g., "chartreuse": [UIColor colorWithRed:0.498 green:1.0 blue:0.0 alpha:1.0],
    };
    
    UIColor *namedColor = namedColors[input];
    if (namedColor) return namedColor;
    
    // Hex parsing (including short forms)
    if ([input hasPrefix:@"#"]) {
        NSString *hex = [input substringFromIndex:1];
        if (hex.length == 3 || hex.length == 4) { // Short hex: #rgb or #rgba
            NSMutableString *expanded = [NSMutableString string];
            for (NSUInteger i = 0; i < hex.length; i++) {
                unichar c = [hex characterAtIndex:i];
                [expanded appendFormat:@"%c%c", c, c];
            }
            hex = expanded;
        }
        if (hex.length == 6 || hex.length == 8) {
            unsigned int hexValue = 0;
            NSScanner *scanner = [NSScanner scannerWithString:hex];
            if ([scanner scanHexInt:&hexValue]) {
                CGFloat r, g, b, a = 1.0;
                if (hex.length == 6) {
                    r = ((hexValue & 0xFF0000) >> 16) / 255.0;
                    g = ((hexValue & 0x00FF00) >> 8) / 255.0;
                    b = (hexValue & 0x0000FF) / 255.0;
                } else {
                    r = ((hexValue & 0xFF000000) >> 24) / 255.0;
                    g = ((hexValue & 0x00FF0000) >> 16) / 255.0;
                    b = ((hexValue & 0x0000FF00) >> 8) / 255.0;
                    a = (hexValue & 0x000000FF) / 255.0;
                }
                return [UIColor colorWithRed:r green:g blue:b alpha:a];
            }
        }
        return nil;
    }
    
    // RGB/RGBA parsing (with percentages)
    if ([input hasPrefix:@"rgb"] || [input hasPrefix:@"rgba"]) {
        NSString *clean = [input stringByReplacingOccurrencesOfString:@"rgb" withString:@""];
        clean = [clean stringByReplacingOccurrencesOfString:@"a" withString:@""];
        clean = [clean stringByReplacingOccurrencesOfString:@"(" withString:@""];
        clean = [clean stringByReplacingOccurrencesOfString:@")" withString:@""];
        clean = [clean stringByReplacingOccurrencesOfString:@" " withString:@""];
        
        NSArray<NSString *> *parts = [clean componentsSeparatedByString:@","];
        if (parts.count == 3 || parts.count == 4) {
            CGFloat r = [self parseColorComponent:parts[0] max:255.0];
            CGFloat g = [self parseColorComponent:parts[1] max:255.0];
            CGFloat b = [self parseColorComponent:parts[2] max:255.0];
            CGFloat a = parts.count == 4 ? [self parseColorComponent:parts[3] max:1.0] : 1.0;
            if (r >= 0 && g >= 0 && b >= 0 && a >= 0) {
                return [UIColor colorWithRed:r green:g blue:b alpha:a];
            }
        }
        return nil;
    }
    
    // HSL/HSLA parsing (basic implementation)
    if ([input hasPrefix:@"hsl"] || [input hasPrefix:@"hsla"]) {
        NSString *clean = [input stringByReplacingOccurrencesOfString:@"hsl" withString:@""];
        clean = [clean stringByReplacingOccurrencesOfString:@"a" withString:@""];
        clean = [clean stringByReplacingOccurrencesOfString:@"(" withString:@""];
        clean = [clean stringByReplacingOccurrencesOfString:@")" withString:@""];
        clean = [clean stringByReplacingOccurrencesOfString:@" " withString:@""];
        
        NSArray<NSString *> *parts = [clean componentsSeparatedByString:@","];
        if (parts.count == 3 || parts.count == 4) {
            CGFloat h = [self parseColorComponent:parts[0] max:360.0];
            CGFloat s = [self parseColorComponent:parts[1] max:1.0];
            CGFloat l = [self parseColorComponent:parts[2] max:1.0];
            CGFloat a = parts.count == 4 ? [self parseColorComponent:parts[3] max:1.0] : 1.0;
            return [UIColor colorWithHue:h / 360.0 saturation:s brightness:l alpha:a]; // Note: Uses HSB approximation
        }
        return nil;
    }
    
    return nil;
}

+ (CGFloat)parseColorComponent:(NSString *)comp max:(CGFloat)max {
    if ([comp hasSuffix:@"%"]) {
        comp = [comp stringByReplacingOccurrencesOfString:@"%" withString:@""];
        return [comp floatValue] / 100.0;
    }
    return [comp floatValue] / max;
}
@end

@implementation UIColor (HexString)
- (NSString *)hexString {
    CGColorRef colorRef = self.CGColor;
    size_t numComponents = CGColorGetNumberOfComponents(colorRef);
    const CGFloat *components = CGColorGetComponents(colorRef);
    
    CGFloat r = 0.0, g = 0.0, b = 0.0, a = 1.0;
    
    if (numComponents == 2) { // Monochrome (grayscale)
        r = components[0];
        g = components[0];
        b = components[0];
        a = components[1];
    } else if (numComponents == 4) { // RGBA
        r = components[0];
        g = components[1];
        b = components[2];
        a = components[3];
    } else if (numComponents == 3) { // RGB (no alpha)
        r = components[0];
        g = components[1];
        b = components[2];
    } else {
        // Unsupported color space (e.g., pattern colors)
        return @"#FFFFFF"; // Or return nil for better error handling
    }
    
    int red = (int)lroundf(r * 255.0f);
    int green = (int)lroundf(g * 255.0f);
    int blue = (int)lroundf(b * 255.0f);
    int alpha = (int)lroundf(a * 255.0f);
    
    // Clamp values to 0-255 to prevent overflow
    red = MAX(0, MIN(255, red));
    green = MAX(0, MIN(255, green));
    blue = MAX(0, MIN(255, blue));
    alpha = MAX(0, MIN(255, alpha));
    
    if (alpha < 255) {
        return [NSString stringWithFormat:@"#%02X%02X%02X%02X", red, green, blue, alpha];
    } else {
        return [NSString stringWithFormat:@"#%02X%02X%02X", red, green, blue];
    }
}
@end
