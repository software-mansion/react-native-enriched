#pragma once

#import "EnrichedTextInputView.h"
#import "StyleTypeEnum.h"
#import <UIKit/UIKit.h>

NS_ASSUME_NONNULL_BEGIN

@interface ShortcutsUtils : NSObject

+ (BOOL)tryHandlingBlockShortcutInRange:(NSRange)range
                        replacementText:(NSString *)text
                                  input:(EnrichedTextInputView *)input;

+ (BOOL)tryHandlingInlineShortcutInRange:(NSRange)range
                         replacementText:(NSString *)text
                                   input:(EnrichedTextInputView *)input;

@end

NS_ASSUME_NONNULL_END
