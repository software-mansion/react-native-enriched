#import <UIKit/UIKit.h>
#pragma once

@interface UIFont (FontExtension)
- (BOOL)isBold;
- (UIFont *)setBold;
- (UIFont *)removeBold;
- (BOOL)isItalic;
- (UIFont *)setItalic;
- (UIFont *)removeItalic;
- (UIFont *)withFontTraits:(UIFont *)from;
- (UIFont *)setSize:(CGFloat)size;
@end
