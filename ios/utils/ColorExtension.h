#import <UIKit/UIKit.h>
#pragma once

@interface UIColor (ColorExtension)
- (BOOL)isEqualToColor:(UIColor *)otherColor;
- (UIColor *)colorWithAlphaIfNotTransparent:(CGFloat)newAlpha;
@end

@interface UIColor (FromString)
+ (UIColor *)colorFromString:(NSString *)string;
@end

@interface UIColor (HexString)
- (NSString *)hexString;
@end
