#import <UIKit/UIKit.h>
#pragma once

@interface ParagraphAttributesUtils : NSObject
+ (BOOL)handleBackspaceInRange:(NSRange)range
               replacementText:(NSString *)text
                         input:(id)input;
+ (BOOL)handleNewlineBackspaceInRange:(NSRange)range
                      replacementText:(NSString *)text
                                input:(id)input;
+ (BOOL)handleResetTypingAttributes:(NSRange)range
                    replacementText:(NSString *)text
                              input:(id)input;
+ (BOOL)isParagraphEmpty:(NSRange)range inString:(NSString *)string;
@end
