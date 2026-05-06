#import "AlignmentEntry.h"
#import "EnrichedTextInputView.h"
#import <UIKit/UIKit.h>

@interface AlignmentUtils : NSObject

+ (void)applyAlignments:(NSArray<AlignmentEntry *> *)alignments
                 offset:(NSInteger)offset
                toInput:(EnrichedTextInputView *)input;

+ (NSArray<AlignmentEntry *> *)
    captureAlignmentsInRange:(NSRange)range
                     inInput:(EnrichedTextInputView *)input;

+ (void)restoreAlignments:(NSArray<AlignmentEntry *> *)alignments
                  inInput:(EnrichedTextInputView *)input;

+ (void)applyAlignmentFromString:(NSString *)alignStr
                         toInput:(EnrichedTextInputView *)input;

+ (void)setAlignment:(NSTextAlignment)alignment
            forRange:(NSRange)range
             inInput:(EnrichedTextInputView *)input
      withTypingAttr:(BOOL)withTypingAttr;

+ (NSString *)alignmentToString:(NSTextAlignment)alignment;

+ (NSTextAlignment)stringToAlignment:(NSString *)alignmentString;

+ (NSString *)currentAlignmentStringForInput:(EnrichedTextInputView *)input;

@end
