#import <UIKit/UIKit.h>
#pragma once

@interface UIColor (ColorExtension)
- (BOOL)isEqualToColor:(UIColor *)otherColor;
- (UIColor *)colorWithDefaultAlpha;
- (UIColor *)colorWithDefaultAlpha:(CGFloat)newAlpha;
@end
