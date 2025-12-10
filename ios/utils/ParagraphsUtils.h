#pragma once
#import <UIKit/UIKit.h>

@interface ParagraphsUtils : NSObject
+ (NSArray *)getSeparateParagraphsRangesIn:(UITextView *)textView
                                     range:(NSRange)range;
+ (NSArray *)getNonNewlineRangesIn:(UITextView *)textView range:(NSRange)range;
+ (NSArray *)getSeparateParagraphsRangesInAttributedString:(NSAttributedString *)attributedString range:(NSRange)range;
+ (NSArray *)getNonNewlineRangesInAttributedString:(NSAttributedString *)attributedString range:(NSRange)range;
@end
