#import <UIKit/UIKit.h>
#pragma once

@interface DotReplacementUtils : NSObject
+ (void)handleDotReplacement:(id)input
                 textStorage:(NSTextStorage *)textStorage
                  editedMask:(NSTextStorageEditActions)editedMask
                 editedRange:(NSRange)editedRange
                       delta:(NSInteger)delta;
@end
