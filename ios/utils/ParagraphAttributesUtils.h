#import <UIKit/UIKit.h>
#pragma once

@interface ParagraphAttributesUtils : NSObject
+ (BOOL)handleBackspaceInRange:(NSRange)range
               replacementText:(NSString *)text
                         input:(id)input;
+ (BOOL)handleParagraphStylesMergeOnBackspace:(NSRange)range
                              replacementText:(NSString *)text
                                        input:(id)input;
@end
