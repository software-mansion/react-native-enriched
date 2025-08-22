#pragma once
#import <UIKit/UIKit.h>
#import "TextDecorationLineEnum.h"
#import "MentionStyleProps.h"

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
- (UIColor *)blockquoteBorderColor;
- (void)setBlockquoteBorderColor:(UIColor *)newValue;
- (CGFloat)blockquoteBorderWidth;
- (void)setBlockquoteBorderWidth:(CGFloat)newValue;
- (CGFloat)blockquoteGapWidth;
- (void)setBlockquoteGapWidth:(CGFloat)newValue;
- (UIColor *)blockquoteColor;
- (void)setBlockquoteColor:(UIColor *)newValue;
- (UIColor *)inlineCodeFgColor;
- (void)setInlineCodeFgColor:(UIColor *)newValue;
- (UIColor *)inlineCodeBgColor;
- (void)setInlineCodeBgColor:(UIColor *)newValue;
- (CGFloat)orderedListGapWidth;
- (void)setOrderedListGapWidth:(CGFloat)newValue;
- (CGFloat)orderedListMarginLeft;
- (void)setOrderedListMarginLeft:(CGFloat)newValue;
- (NSString *)orderedListMarkerFontWeight;
- (void)setOrderedListMarkerFontWeight:(NSString *)newValue;
- (UIColor *)orderedListMarkerColor;
- (void)setOrderedListMarkerColor:(UIColor *)newValue;
- (UIFont *)orderedListMarkerFont;
- (CGFloat)orderedListMarkerWidth;
- (UIColor *)unorderedListBulletColor;
- (void)setUnorderedListBulletColor:(UIColor *)newValue;
- (CGFloat)unorderedListBulletSize;
- (void)setUnorderedListBulletSize:(CGFloat)newValue;
- (CGFloat)unorderedListGapWidth;
- (void)setUnorderedListGapWidth:(CGFloat)newValue;
- (CGFloat)unorderedListMarginLeft;
- (void)setUnorderedListMarginLeft:(CGFloat)newValue;
- (UIColor *)linkColor;
- (void)setLinkColor:(UIColor *)newValue;
- (TextDecorationLineEnum)linkDecorationLine;
- (void)setLinkDecorationLine:(TextDecorationLineEnum)newValue;
- (void)setMentionStyleProps:(NSDictionary *)newValue;
- (MentionStyleProps *)mentionStylePropsForIndicator:(NSString *)indicator;
@end
