#pragma once
#import <Foundation/Foundation.h>
#import "StylePair.h"
#import "EnrichedTextInputView.h"

@interface OccurenceUtils : NSObject
+ (BOOL)detect:(NSAttributedStringKey _Nonnull)key
      inString:(NSAttributedString * _Nonnull)string
        inRange:(NSRange)range
  withCondition:(BOOL (NS_NOESCAPE ^_Nonnull)(id _Nullable value, NSRange range))condition;

+ (BOOL)detectMultiple:(NSArray<NSAttributedStringKey> * _Nonnull)keys
              inString:(NSAttributedString * _Nonnull)string
                inRange:(NSRange)range
          withCondition:(BOOL (NS_NOESCAPE ^_Nonnull)(id _Nullable value, NSRange range))condition;

+ (BOOL)any:(NSAttributedStringKey _Nonnull)key
    inString:(NSAttributedString * _Nonnull)string
      inRange:(NSRange)range
withCondition:(BOOL (NS_NOESCAPE ^_Nonnull)(id _Nullable value, NSRange range))condition;

+ (BOOL)anyMultiple:(NSArray<NSAttributedStringKey> * _Nonnull)keys
           inString:(NSAttributedString * _Nonnull)string
             inRange:(NSRange)range
       withCondition:(BOOL (NS_NOESCAPE ^_Nonnull)(id _Nullable value, NSRange range))condition;

+ (NSArray<StylePair *> * _Nonnull)all:(NSAttributedStringKey _Nonnull)key
                             inString:(NSAttributedString * _Nonnull)string
                               inRange:(NSRange)range
                         withCondition:(BOOL (NS_NOESCAPE ^_Nonnull)(id _Nullable value, NSRange range))condition;

+ (NSArray<StylePair *> * _Nonnull)allMultiple:(NSArray<NSAttributedStringKey> * _Nonnull)keys
                                      inString:(NSAttributedString * _Nonnull)string
                                        inRange:(NSRange)range
                                  withCondition:(BOOL (NS_NOESCAPE ^_Nonnull)(id _Nullable value, NSRange range))condition;
+ (BOOL)detect:(NSAttributedStringKey _Nonnull)key
     withInput:(EnrichedTextInputView * _Nonnull)input
       inRange:(NSRange)range
 withCondition:(BOOL (NS_NOESCAPE ^_Nonnull)(id _Nullable value, NSRange range))condition;

+ (BOOL)detect:(NSAttributedStringKey _Nonnull)key
     withInput:(EnrichedTextInputView * _Nonnull)input
       atIndex:(NSUInteger)index
  checkPrevious:(BOOL)checkPrev
 withCondition:(BOOL (NS_NOESCAPE ^_Nonnull)(id _Nullable value, NSRange range))condition;

+ (BOOL)detectMultiple:(NSArray<NSAttributedStringKey> * _Nonnull)keys
             withInput:(EnrichedTextInputView * _Nonnull)input
               inRange:(NSRange)range
         withCondition:(BOOL (NS_NOESCAPE ^_Nonnull)(id _Nullable value, NSRange range))condition;

+ (BOOL)any:(NSAttributedStringKey _Nonnull)key
   withInput:(EnrichedTextInputView * _Nonnull)input
     inRange:(NSRange)range
withCondition:(BOOL (NS_NOESCAPE ^_Nonnull)(id _Nullable value, NSRange range))condition;

+ (BOOL)anyMultiple:(NSArray<NSAttributedStringKey> * _Nonnull)keys
          withInput:(EnrichedTextInputView * _Nonnull)input
            inRange:(NSRange)range
      withCondition:(BOOL (NS_NOESCAPE ^_Nonnull)(id _Nullable value, NSRange range))condition;

+ (NSArray<StylePair *> * _Nonnull)all:(NSAttributedStringKey _Nonnull)key
                              withInput:(EnrichedTextInputView * _Nonnull)input
                                inRange:(NSRange)range
                          withCondition:(BOOL (NS_NOESCAPE ^_Nonnull)(id _Nullable value, NSRange range))condition;

+ (NSArray<StylePair *> * _Nonnull)allMultiple:(NSArray<NSAttributedStringKey> * _Nonnull)keys
                                     withInput:(EnrichedTextInputView * _Nonnull)input
                                       inRange:(NSRange)range
                                 withCondition:(BOOL (NS_NOESCAPE ^_Nonnull)(id _Nullable value, NSRange range))condition;

+ (NSArray * _Nonnull)getRangesWithout:(NSArray<NSNumber *> * _Nonnull)types
                              withInput:(EnrichedTextInputView * _Nonnull)input
                                inRange:(NSRange)range;

@end
