#pragma once
#import "AttributeEntry.h"
#import "EnrichedStyleHost.h"
#import "StylePair.h"
#import "StyleTypeEnum.h"
#import <UIKit/UIKit.h>

@interface StyleBase : NSObject
@property(nonatomic, weak) id<EnrichedStyleHost> host;
+ (StyleType)getType;
- (NSString *)getKey;
- (NSString *)getValue;
- (BOOL)isParagraph;
- (BOOL)needsZWS;
- (instancetype)initWithHost:(id<EnrichedStyleHost>)host;
- (NSRange)actualUsedRange:(NSRange)range;
- (void)toggle:(NSRange)range;
- (void)add:(NSRange)range
        withTyping:(BOOL)withTyping
    withDirtyRange:(BOOL)withDirtyRange;
- (void)add:(NSRange)range
         withValue:(NSString *)value
        withTyping:(BOOL)withTyping
    withDirtyRange:(BOOL)withDirtyRange;
- (void)remove:(NSRange)range withDirtyRange:(BOOL)withDirtyRange;
- (void)addTypingWithValue:(NSString *)value;
- (void)removeTyping;
- (BOOL)styleCondition:(id)value range:(NSRange)range;
- (BOOL)detect:(NSRange)range;
- (BOOL)any:(NSRange)range;
- (NSArray<StylePair *> *)all:(NSRange)range;
- (void)applyStyling:(NSRange)range;
- (void)reapplyFromStylePair:(StylePair *)pair;
- (AttributeEntry *)getEntryIfPresent:(NSRange)range;
@end
