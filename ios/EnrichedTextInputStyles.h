#import <Foundation/Foundation.h>
#import "StyleHeaders.h"

@class EnrichedTextInputView;

FOUNDATION_EXPORT NSDictionary<NSNumber *, id<BaseStyleProtocol>> *
EnrichedTextInputMakeStyles(__kindof EnrichedTextInputView *input);

FOUNDATION_EXPORT NSDictionary<NSNumber *, NSArray<NSNumber *> *> *
EnrichedTextInputConflictingStyles(void);

FOUNDATION_EXPORT NSDictionary<NSNumber *, NSArray<NSNumber *> *> *
EnrichedTextInputBlockingStyles(void);
