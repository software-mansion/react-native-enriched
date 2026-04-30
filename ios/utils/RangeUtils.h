#pragma once
#import <UIKit/UIKit.h>

@interface RangeUtils : NSObject
+ (NSArray *)getSeparateParagraphsRangesIn:(UITextView *)textView
                                     range:(NSRange)range;
+ (NSArray *)getNonNewlineRangesIn:(UITextView *)textView range:(NSRange)range;
+ (NSArray *)connectAndDedupeRanges:(NSArray *)ranges;
+ (NSArray *)shiftRanges:(NSArray *)ranges
         withEditedRange:(NSRange)editedRange
          changeInLength:(NSInteger)delta;
@end
