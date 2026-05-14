#import "EnrichedTextInputView.h"
#import <UIKit/UIKit.h>
#pragma once

@interface ParagraphAttributesUtils : NSObject
+ (BOOL)handleBackspaceInRange:(NSRange)range
               replacementText:(NSString *)text
                         input:(id)input;
+ (BOOL)handleParagraphStylesMergeOnBackspace:(NSRange)range
                              replacementText:(NSString *)text
                                        input:(id)input;
+ (BOOL)handleResetTypingAttributesOnBackspace:(NSRange)range
                               replacementText:(NSString *)text
                                         input:(id)input;
+ (BOOL)isParagraphEmpty:(NSRange)range inString:(NSString *)string;
+ (void)resetTypingAttributes:(EnrichedTextInputView *)input
          preservingAlignment:(NSTextAlignment)alignment;
@end
