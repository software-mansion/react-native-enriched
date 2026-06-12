#pragma once

#import "EnrichedTextInputView.h"
#import "StyleTypeEnum.h"
#import <UIKit/UIKit.h>

NS_ASSUME_NONNULL_BEGIN

@interface ShortcutsUtils : NSObject

+ (BOOL)tryHandlingParagraphShortcutsInRange:(NSRange)range
                             replacementText:(NSString *)text
                                       input:(EnrichedTextInputView *)input;

+ (BOOL)tryHandlingInlineShortcutsInRange:(NSRange)range
                          replacementText:(NSString *)text
                                    input:(EnrichedTextInputView *)input;

@end

NS_ASSUME_NONNULL_END
