#import "EnrichedTextInputView.h"
#import <UIKit/UIKit.h>

@interface AlignmentUtils : NSObject

+ (void)applyAlignmentFromString:(NSString *)alignStr
                         toInput:(EnrichedTextInputView *)input;

+ (void)setAlignment:(NSTextAlignment)alignment
            forRange:(NSRange)range
             inInput:(EnrichedTextInputView *)input;

+ (NSString *)alignmentToString:(NSTextAlignment)alignment;

+ (NSString *)currentAlignmentStringForInput:(EnrichedTextInputView *)input;

@end
