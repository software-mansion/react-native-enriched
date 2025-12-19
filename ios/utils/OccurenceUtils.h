#pragma once
#import "EnrichedTextInputView.h"
#import "StylePair.h"

@interface OccurenceUtils : NSObject
+ (BOOL)detect:(NSAttributedStringKey _Nonnull)key
        withInput:(EnrichedTextInputView *_Nonnull)input
          inRange:(NSRange)range
    withCondition:(BOOL(NS_NOESCAPE ^ _Nonnull)(id _Nullable value,
                                                NSRange range))condition;
+ (BOOL)detect:(NSAttributedStringKey _Nonnull)key
        withInput:(EnrichedTextInputView *_Nonnull)input
          atIndex:(NSUInteger)index
    checkPrevious:(BOOL)check
    withCondition:(BOOL(NS_NOESCAPE ^ _Nonnull)(id _Nullable value,
                                                NSRange range))condition;
+ (BOOL)detectMultiple:(NSArray<NSAttributedStringKey> *_Nonnull)keys
             withInput:(EnrichedTextInputView *_Nonnull)input
               inRange:(NSRange)range
         withCondition:(BOOL(NS_NOESCAPE ^ _Nonnull)(id _Nullable value,
                                                     NSRange range))condition;
+ (BOOL)any:(NSAttributedStringKey _Nonnull)key
        withInput:(EnrichedTextInputView *_Nonnull)input
          inRange:(NSRange)range
    withCondition:(BOOL(NS_NOESCAPE ^ _Nonnull)(id _Nullable value,
                                                NSRange range))condition;
+ (BOOL)anyMultiple:(NSArray<NSAttributedStringKey> *_Nonnull)keys
          withInput:(EnrichedTextInputView *_Nonnull)input
            inRange:(NSRange)range
      withCondition:(BOOL(NS_NOESCAPE ^ _Nonnull)(id _Nullable value,
                                                  NSRange range))condition;
+ (NSArray<StylePair *> *_Nullable)all:(NSAttributedStringKey _Nonnull)key
                             withInput:(EnrichedTextInputView *_Nonnull)input
                               inRange:(NSRange)range
                         withCondition:(BOOL(NS_NOESCAPE ^
                                             _Nonnull)(id _Nullable value,
                                                       NSRange range))condition;
+ (NSArray<StylePair *> *_Nullable)
      allMultiple:(NSArray<NSAttributedStringKey> *_Nonnull)keys
        withInput:(EnrichedTextInputView *_Nonnull)input
          inRange:(NSRange)range
    withCondition:(BOOL(NS_NOESCAPE ^ _Nonnull)(id _Nullable value,
                                                NSRange range))condition;
+ (NSArray *_Nonnull)getRangesWithout:(NSArray<NSNumber *> *_Nonnull)types
                            withInput:(EnrichedTextInputView *_Nonnull)input
                              inRange:(NSRange)range;
@end
