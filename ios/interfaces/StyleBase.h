#pragma once
#import "AttributeEntry.h"
#import "StylePair.h"
#import "StyleTypeEnum.h"
#import <UIKit/UIKit.h>

@class EnrichedTextInputView;

@interface StyleBase : NSObject
@property(nonatomic, weak) EnrichedTextInputView *input;
+ (StyleType)getType;
- (NSString *)getKey;
- (NSString *)getValue;
- (BOOL)isParagraph;
- (BOOL)needsZWS;
- (instancetype)initWithInput:(EnrichedTextInputView *)input;
- (NSRange)actualUsedRange:(NSRange)range;
- (void)toggle:(NSRange)range;
- (void)add:(NSRange)range
        withTyping:(BOOL)withTyping
    withDirtyRange:(BOOL)withDirtyRange;
- (void)remove:(NSRange)range withDirtyRange:(BOOL)withDirtyRange;
- (void)addTyping;
- (void)removeTyping;
- (BOOL)styleCondition:(id)value range:(NSRange)range;
- (BOOL)detect:(NSRange)range;
- (BOOL)any:(NSRange)range;
- (NSArray<StylePair *> *)all:(NSRange)range;
- (void)applyStyling:(NSRange)range;
- (void)reapplyAttributesFromStylePair:(StylePair *)pair;
- (AttributeEntry *)getEntryIfPresent:(NSRange)range;
@end
