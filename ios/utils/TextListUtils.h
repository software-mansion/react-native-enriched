#pragma once
#import <UIKit/UIKit.h>

@interface TextListUtils : NSObject

// Appends value to the array. If exclusivePrefix is non-nil, any existing
// entry whose markerFormat starts with that prefix is evicted first, ensuring
// only one value from the family is present at a time.
+ (NSArray<NSTextList *> *)textListsByAdding:(NSString *)value
                         withExclusivePrefix:(nullable NSString *)prefix
                                     toArray:(nullable NSArray<NSTextList *> *)
                                                 existing;

// Returns a new array with every entry whose markerFormat equals value removed.
+ (NSArray<NSTextList *> *)
    textListsByRemoving:(NSString *)value
              fromArray:(nullable NSArray<NSTextList *> *)existing;

// Returns YES if any entry's markerFormat equals value exactly.
+ (BOOL)textLists:(nullable NSArray<NSTextList *> *)textLists
    containsValue:(NSString *)value;

// Returns YES if any entry's markerFormat starts with prefix.
+ (BOOL)textLists:(nullable NSArray<NSTextList *> *)textLists
    containsPrefix:(NSString *)prefix;

// Returns the first entry whose markerFormat starts with prefix, or nil.
+ (nullable NSTextList *)
    firstTextListWithPrefix:(NSString *)prefix
                    inArray:(nullable NSArray<NSTextList *> *)textLists;

@end
