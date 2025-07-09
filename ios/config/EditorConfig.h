#pragma once
#import <UIKit/UIKit.h>

@interface EditorConfig: NSObject<NSCopying>
- (instancetype) init;
- (UIColor *)primaryColor;
- (void)setPrimaryColor:(UIColor *)newValue;
- (NSNumber *)primaryFontSize;
- (void)setPrimaryFontSize:(NSNumber *)newValue;
- (NSString *)primaryFontWeight;
- (void)setPrimaryFontWeight:(NSString *)newValue;
- (NSString *)primaryFontFamily;
- (void)setPrimaryFontFamily:(NSString *)newValue;
- (UIFont *)primaryFont;
- (UIFont *)monospacedFont;
- (NSSet<NSNumber*>*)mentionIndicators;
- (void)setMentionIndicators:(NSSet<NSNumber*>*)newValue;
- (CGFloat)h1FontSize;
- (void)setH1FontSize:(CGFloat)newValue;
- (CGFloat)h2FontSize;
- (void)setH2FontSize:(CGFloat)newValue;
- (CGFloat)h3FontSize;
- (void)setH3FontSize:(CGFloat)newValue;
- (UIColor *)blockquoteColor;
- (void)setBlockquoteColor:(UIColor *)newValue;
- (CGFloat)blockquoteWidth;
- (void)setBlockquoteWidth:(CGFloat)newValue;
- (CGFloat)blockquoteGapWidth;
- (void)setBlockquoteGapWidth:(CGFloat)newValue;

- (UIColor *)inlineCodeFgColor;
- (void)setInlineCodeFgColor:(UIColor *)newValue;
- (UIColor *)inlineCodeBgColor;
- (void)setInlineCodeBgColor:(UIColor *)newValue;
@end
