#import <UIKit/UIKit.h>
#import <EditorConfig.h>
#pragma once

@interface UIFont (FontExtension)
- (BOOL)isBold;
- (UIFont *)setBold;
- (UIFont *)removeBold;
- (BOOL)isItalic;
- (UIFont *)setItalic;
- (UIFont *)removeItalic;
- (BOOL)isMonospace:(EditorConfig *)withConfig;
- (UIFont *)withFontTraits:(UIFont *)from;
- (UIFont *)setSize:(CGFloat)size;
@end
