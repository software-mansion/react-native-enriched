#import "TextListUtils.h"

@implementation TextListUtils

+ (NSArray<NSTextList *> *)textListsByAdding:(NSString *)value
                         withExclusivePrefix:(nullable NSString *)prefix
                                     toArray:(nullable NSArray<NSTextList *> *)
                                                 existing {
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

+ (NSArray<NSTextList *> *)
    textListsByRemoving:(NSString *)value
              fromArray:(nullable NSArray<NSTextList *> *)existing {
  NSMutableArray<NSTextList *> *updated = [NSMutableArray array];
  for (NSTextList *list in existing) {
    if (![list.markerFormat isEqualToString:value]) {
      [updated addObject:list];
    }
  }
  return updated;
}

+ (BOOL)textLists:(nullable NSArray<NSTextList *> *)textLists
    containsValue:(NSString *)value {
  for (NSTextList *list in textLists) {
    if ([list.markerFormat isEqualToString:value]) {
      return YES;
    }
  }
  return NO;
}

+ (BOOL)textLists:(nullable NSArray<NSTextList *> *)textLists
    containsPrefix:(NSString *)prefix {
  for (NSTextList *list in textLists) {
    if ([list.markerFormat hasPrefix:prefix]) {
      return YES;
    }
  }
  return NO;
}

+ (nullable NSTextList *)
    firstTextListWithPrefix:(NSString *)prefix
                    inArray:(nullable NSArray<NSTextList *> *)textLists {
  for (NSTextList *list in textLists) {
    if ([list.markerFormat hasPrefix:prefix]) {
      return list;
    }
  }
  return nil;
}

@end
