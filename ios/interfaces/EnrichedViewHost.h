#pragma once
#import "AttributesManager.h"
#import "EnrichedConfig.h"
#import "StyleTypeEnum.h"
#import <UIKit/UIKit.h>

@protocol EnrichedViewHost <NSObject>
@required
@property(nonatomic, readonly) UITextView *textView;
@property(nonatomic, readonly) EnrichedConfig *config;
@property(nonatomic, readonly) NSDictionary<NSNumber *, id> *stylesDict;
@property(nonatomic, readonly, nullable) AttributesManager *attributesManager;
@property(nonatomic, readonly, nullable)
    NSMutableDictionary<NSNumber *, NSArray<NSNumber *> *> *conflictingStyles;
@property(nonatomic, readonly, nullable)
    NSMutableDictionary<NSNumber *, NSArray<NSNumber *> *> *blockingStyles;
@property(nonatomic, readonly, nullable)
    NSMutableDictionary<NSAttributedStringKey, id> *defaultTypingAttributes;
@property(nonatomic) BOOL blockEmitting;
@optional
- (BOOL)handleStyleBlocksAndConflicts:(StyleType)type range:(NSRange)range;
- (void)emitOnLinkDetectedEvent:(id _Nonnull)linkData range:(NSRange)range;
- (void)emitOnMentionEvent:(NSString *_Nonnull)indicator
                      text:(NSString *_Nullable)text;
@end
