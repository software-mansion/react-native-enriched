#pragma once
#import "EnrichedStyleHost.h"
#import "StylePair.h"

@interface OccurenceUtils : NSObject
+ (BOOL)detect:(NSAttributedStringKey _Nonnull)key
         withHost:(id<EnrichedStyleHost> _Nonnull)host
          inRange:(NSRange)range
    withCondition:(BOOL(NS_NOESCAPE ^ _Nonnull)(id _Nullable value,
                                                NSRange range))condition;
+ (BOOL)detect:(NSAttributedStringKey _Nonnull)key
         withHost:(id<EnrichedStyleHost> _Nonnull)host
          atIndex:(NSUInteger)index
    checkPrevious:(BOOL)checkPrev
    withCondition:(BOOL(NS_NOESCAPE ^ _Nonnull)(id _Nullable value,
                                                NSRange range))condition;
+ (BOOL)detectMultiple:(NSArray<NSAttributedStringKey> *_Nonnull)keys
              withHost:(id<EnrichedStyleHost> _Nonnull)host
               inRange:(NSRange)range
         withCondition:(BOOL(NS_NOESCAPE ^ _Nonnull)(id _Nullable value,
                                                     NSRange range))condition;
+ (BOOL)any:(NSAttributedStringKey _Nonnull)key
         withHost:(id<EnrichedStyleHost> _Nonnull)host
          inRange:(NSRange)range
    withCondition:(BOOL(NS_NOESCAPE ^ _Nonnull)(id _Nullable value,
                                                NSRange range))condition;
+ (BOOL)anyMultiple:(NSArray<NSAttributedStringKey> *_Nonnull)keys
           withHost:(id<EnrichedStyleHost> _Nonnull)host
            inRange:(NSRange)range
      withCondition:(BOOL(NS_NOESCAPE ^ _Nonnull)(id _Nullable value,
                                                  NSRange range))condition;
+ (NSArray<StylePair *> *_Nullable)all:(NSAttributedStringKey _Nonnull)key
                              withHost:(id<EnrichedStyleHost> _Nonnull)host
                               inRange:(NSRange)range
                         withCondition:(BOOL(NS_NOESCAPE ^
                                             _Nonnull)(id _Nullable value,
                                                       NSRange range))condition;
+ (NSArray<StylePair *> *_Nullable)
      allMultiple:(NSArray<NSAttributedStringKey> *_Nonnull)keys
         withHost:(id<EnrichedStyleHost> _Nonnull)host
          inRange:(NSRange)range
    withCondition:(BOOL(NS_NOESCAPE ^ _Nonnull)(id _Nullable value,
                                                NSRange range))condition;
@end
