#import <UIKit/UIKit.h>
#pragma once

@interface UIFont (FontExtension)
- (BOOL)isBold;
- (UIFont *)setBold;
- (BOOL)isItalic;
- (UIFont *)setItalic;
- (UIFont *)withFontTraits:(UIFont *)from;
- (UIFont *)setSize:(CGFloat)size;
@end
