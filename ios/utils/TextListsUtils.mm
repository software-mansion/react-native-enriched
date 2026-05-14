#import "TextListsUtils.h"

@implementation TextListsUtils

+ (NSArray<NSTextList *> *_Nonnull)
      textListsByAdding:(NSString *_Nonnull)value
    withExclusivePrefix:(NSString *_Nullable)prefix
                toArray:(NSArray<NSTextList *> *_Nullable)existing {
  NSMutableArray<NSTextList *> *updated =
      existing ? [existing mutableCopy] : [NSMutableArray array];

  if (prefix != nil) {
    NSUInteger i = 0;
    while (i < updated.count) {
      if ([updated[i].markerFormat hasPrefix:prefix]) {
        if ([updated[i].markerFormat isEqualToString:value]) {
          return updated;
        }
        [updated removeObjectAtIndex:i];
      } else {
        i++;
      }
    }
  } else {
    for (NSTextList *list in updated) {
      if ([list.markerFormat isEqualToString:value]) {
        return updated;
      }
    }
  }

  [updated addObject:[[NSTextList alloc] initWithMarkerFormat:value options:0]];
  return updated;
}

+ (NSArray<NSTextList *> *_Nonnull)
    textListsByRemoving:(NSString *_Nonnull)value
             withPrefix:(NSString *_Nullable)prefix
              fromArray:(NSArray<NSTextList *> *_Nullable)existing {
  NSMutableArray<NSTextList *> *updated = [NSMutableArray array];
  for (NSTextList *list in existing) {
    if ((prefix == nullptr && ![list.markerFormat isEqualToString:value]) ||
        (prefix != nullptr && ![list.markerFormat hasPrefix:prefix])) {
      [updated addObject:list];
    }
  }
  return updated;
}

+ (NSArray<NSTextList *> *_Nonnull)
    textListsByRemovingPrefix:(NSString *_Nullable)prefix
                    fromArray:(NSArray<NSTextList *> *_Nullable)existing {
  NSMutableArray<NSTextList *> *updated = [NSMutableArray array];
  for (NSTextList *list in existing) {
    if (![list.markerFormat hasPrefix:prefix]) {
      [updated addObject:list];
    }
  }
  return updated;
}

+ (BOOL)textLists:(NSArray<NSTextList *> *_Nullable)textLists
    containsValue:(NSString *_Nonnull)value {
  for (NSTextList *list in textLists) {
    if ([list.markerFormat isEqualToString:value]) {
      return YES;
    }
  }
  return NO;
}

+ (BOOL)textLists:(NSArray<NSTextList *> *_Nullable)textLists
    containsPrefix:(NSString *_Nullable)prefix {
  for (NSTextList *list in textLists) {
    if ([list.markerFormat hasPrefix:prefix]) {
      return YES;
    }
  }
  return NO;
}

+ (NSTextList *_Nullable)
    firstTextListWithPrefix:(NSString *_Nullable)prefix
                    inArray:(NSArray<NSTextList *> *_Nullable)textLists {
  for (NSTextList *list in textLists) {
    if ([list.markerFormat hasPrefix:prefix]) {
      return list;
    }
  }
  return nil;
}

@end
