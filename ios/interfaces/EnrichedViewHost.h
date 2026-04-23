#pragma once
#import "EnrichedConfig.h"
#import "InputAttributesManager.h"
#import "StyleTypeEnum.h"
#import <UIKit/UIKit.h>

@protocol EnrichedViewHost <NSObject>
@required
@property(nonatomic, readonly) UITextView *_Nonnull textView;
@property(nonatomic, readonly) EnrichedConfig *_Nonnull config;
@property(nonatomic, readonly)
    NSDictionary<NSNumber *, id> *_Nonnull stylesDict;
@property(nonatomic, readonly, nullable)
    NSMutableDictionary<NSNumber *, NSArray<NSNumber *> *> *conflictingStyles;
@property(nonatomic, readonly, nullable)
    NSMutableDictionary<NSNumber *, NSArray<NSNumber *> *> *blockingStyles;
@property(nonatomic, readonly, nullable)
    NSMutableDictionary<NSAttributedStringKey, id> *defaultTypingAttributes;
@property(nonatomic) BOOL blockEmitting;
@optional
@property(nonatomic, readonly, nullable)
    InputAttributesManager *attributesManager;
- (void)emitOnLinkDetectedEvent:(id _Nonnull)linkData range:(NSRange)range;
- (void)emitOnMentionEvent:(NSString *_Nonnull)indicator
                      text:(NSString *_Nullable)text;
@end
