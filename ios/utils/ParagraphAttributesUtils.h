#import <UIKit/UIKit.h>
#pragma once

@interface ParagraphAttributesUtils : NSObject
+ (BOOL)handleBackspaceInRange:(NSRange)range
               replacementText:(NSString *)text
                         input:(id)input;
+ (BOOL)handleNewlineBackspaceInRange:(NSRange)range
                      replacementText:(NSString *)text
                                input:(id)input;
@end
