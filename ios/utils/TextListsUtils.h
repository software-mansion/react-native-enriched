#pragma once
#import <UIKit/UIKit.h>

@interface TextListsUtils : NSObject

// Appends value to the array. If exclusivePrefix is non-nil, any existing
// entry whose markerFormat starts with that prefix is evicted first, ensuring
// only one value from the family is present at a time.
+ (NSArray<NSTextList *> *_Nonnull)
      textListsByAdding:(NSString *_Nonnull)value
    withExclusivePrefix:(NSString *_Nullable)prefix
                toArray:(NSArray<NSTextList *> *_Nullable)existing;

// Returns a new array without entries whose markerFormat equals value removed
// or whose markerFormat starts with prefix
+ (NSArray<NSTextList *> *_Nonnull)
    textListsByRemoving:(NSString *_Nonnull)value
             withPrefix:(NSString *_Nullable)prefix
              fromArray:(NSArray<NSTextList *> *_Nullable)existing;

// Returns a new array without entries whose markerFormat starts with prefix
+ (NSArray<NSTextList *> *_Nonnull)
    textListsByRemovingPrefix:(NSString *_Nullable)prefix
                    fromArray:(NSArray<NSTextList *> *_Nullable)existing;

// Returns YES if any entry's markerFormat equals value exactly.
+ (BOOL)textLists:(NSArray<NSTextList *> *_Nullable)textLists
    containsValue:(NSString *_Nonnull)value;

// Returns YES if any entry's markerFormat starts with prefix.
+ (BOOL)textLists:(NSArray<NSTextList *> *_Nullable)textLists
    containsPrefix:(NSString *_Nullable)prefix;

// Returns the first entry with a markerFormat that starts with prefix,
// otherwise nil.
+ (NSTextList *_Nullable)
    firstTextListWithPrefix:(NSString *_Nullable)prefix
                    inArray:(NSArray<NSTextList *> *_Nullable)textLists;

@end
