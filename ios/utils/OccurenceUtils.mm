#import "OccurenceUtils.h"

@implementation OccurenceUtils

+ (BOOL)detect:(NSAttributedStringKey _Nonnull)key
        withInput:(EnrichedTextInputView *_Nonnull)input
          inRange:(NSRange)range
    withCondition:(BOOL(NS_NOESCAPE ^ _Nonnull)(id _Nullable value,
                                                NSRange range))condition {
  __block NSInteger totalLength = 0;
  [input->textView.textStorage
      enumerateAttribute:key
                 inRange:range
                 options:0
              usingBlock:^(id _Nullable value, NSRange range,
                           BOOL *_Nonnull stop) {
                if (condition(value, range)) {
                  totalLength += range.length;
                }
              }];
  return totalLength == range.length;
}

// checkPrevious flag is used for styles like lists or blockquotes
// it means that first character of paragraph will be checked instead if the
// detection is not in input's selected range and at the end of the input
+ (BOOL)detect:(NSAttributedStringKey _Nonnull)key
        withInput:(EnrichedTextInputView *_Nonnull)input
          atIndex:(NSUInteger)index
    checkPrevious:(BOOL)checkPrev
    withCondition:(BOOL(NS_NOESCAPE ^ _Nonnull)(id _Nullable value,
                                                NSRange range))condition {
  NSRange detectionRange = NSMakeRange(index, 0);
  id attrValue;
  if (NSEqualRanges(input->textView.selectedRange, detectionRange)) {
    attrValue = input->textView.typingAttributes[key];
  } else if (index == input->textView.textStorage.string.length) {
    if (checkPrev) {
      NSRange paragraphRange = [input->textView.textStorage.string
          paragraphRangeForRange:detectionRange];
      if (paragraphRange.location == detectionRange.location) {
        return NO;
      } else {
        return [self detect:key
                  withInput:input
                    inRange:NSMakeRange(paragraphRange.location, 1)
              withCondition:condition];
      }
    } else {
      return NO;
    }
  } else {
    NSRange attrRange = NSMakeRange(0, 0);
    attrValue = [input->textView.textStorage attribute:key
                                               atIndex:index
                                        effectiveRange:&attrRange];
  }
  return condition(attrValue, detectionRange);
}

+ (BOOL)detectMultiple:(NSArray<NSAttributedStringKey> *_Nonnull)keys
             withInput:(EnrichedTextInputView *_Nonnull)input
               inRange:(NSRange)range
         withCondition:(BOOL(NS_NOESCAPE ^ _Nonnull)(id _Nullable value,
                                                     NSRange range))condition {
  __block NSInteger totalLength = 0;
  for (NSString *key in keys) {
    [input->textView.textStorage
        enumerateAttribute:key
                   inRange:range
                   options:0
                usingBlock:^(id _Nullable value, NSRange range,
                             BOOL *_Nonnull stop) {
                  if (condition(value, range)) {
                    totalLength += range.length;
                  }
                }];
  }
  return totalLength == range.length;
}

+ (BOOL)any:(NSAttributedStringKey _Nonnull)key
        withInput:(EnrichedTextInputView *_Nonnull)input
          inRange:(NSRange)range
    withCondition:(BOOL(NS_NOESCAPE ^ _Nonnull)(id _Nullable value,
                                                NSRange range))condition {
  __block BOOL found = NO;
  [input->textView.textStorage
      enumerateAttribute:key
                 inRange:range
                 options:0
              usingBlock:^(id _Nullable value, NSRange range,
                           BOOL *_Nonnull stop) {
                if (condition(value, range)) {
                  found = YES;
                  *stop = YES;
                }
              }];
  return found;
}

+ (BOOL)anyMultiple:(NSArray<NSAttributedStringKey> *_Nonnull)keys
          withInput:(EnrichedTextInputView *_Nonnull)input
            inRange:(NSRange)range
      withCondition:(BOOL(NS_NOESCAPE ^ _Nonnull)(id _Nullable value,
                                                  NSRange range))condition {
  __block BOOL found = NO;
  for (NSString *key in keys) {
    [input->textView.textStorage
        enumerateAttribute:key
                   inRange:range
                   options:0
                usingBlock:^(id _Nullable value, NSRange range,
                             BOOL *_Nonnull stop) {
                  if (condition(value, range)) {
                    found = YES;
                    *stop = YES;
                  }
                }];
    if (found) {
      return YES;
    }
  }
  return NO;
}

+ (NSArray<StylePair *> *_Nullable)all:(NSAttributedStringKey _Nonnull)key
                             withInput:(EnrichedTextInputView *_Nonnull)input
                               inRange:(NSRange)range
                         withCondition:
                             (BOOL(NS_NOESCAPE ^ _Nonnull)(id _Nullable value,
                                                           NSRange range))
                                 condition {
  __block NSMutableArray<StylePair *> *occurences =
      [[NSMutableArray<StylePair *> alloc] init];
  [input->textView.textStorage
      enumerateAttribute:key
                 inRange:range
                 options:0
              usingBlock:^(id _Nullable value, NSRange range,
                           BOOL *_Nonnull stop) {
                if (condition(value, range)) {
                  StylePair *pair = [[StylePair alloc] init];
                  pair.rangeValue = [NSValue valueWithRange:range];
                  pair.styleValue = value;
                  [occurences addObject:pair];
                }
              }];
  return occurences;
}

+ (NSArray<StylePair *> *_Nullable)
      allMultiple:(NSArray<NSAttributedStringKey> *_Nonnull)keys
        withInput:(EnrichedTextInputView *_Nonnull)input
          inRange:(NSRange)range
    withCondition:(BOOL(NS_NOESCAPE ^ _Nonnull)(id _Nullable value,
                                                NSRange range))condition {
  __block NSMutableArray<StylePair *> *occurences =
      [[NSMutableArray<StylePair *> alloc] init];
  for (NSString *key in keys) {
    [input->textView.textStorage
        enumerateAttribute:key
                   inRange:range
                   options:0
                usingBlock:^(id _Nullable value, NSRange range,
                             BOOL *_Nonnull stop) {
                  if (condition(value, range)) {
                    StylePair *pair = [[StylePair alloc] init];
                    pair.rangeValue = [NSValue valueWithRange:range];
                    pair.styleValue = value;
                    [occurences addObject:pair];
                  }
                }];
  }
  return occurences;
}

+ (NSArray *_Nonnull)getRangesWithout:(NSArray<NSNumber *> *_Nonnull)types
                            withInput:(EnrichedTextInputView *_Nonnull)input
                              inRange:(NSRange)range {
  NSMutableArray<id> *activeStyleObjects = [[NSMutableArray alloc] init];
  for (NSNumber *type in types) {
    id<BaseStyleProtocol> styleClass = input->stylesDict[type];
    [activeStyleObjects addObject:styleClass];
  }

  if (activeStyleObjects.count == 0) {
    return @[ [NSValue valueWithRange:range] ];
  }

  NSMutableArray<NSValue *> *newRanges = [[NSMutableArray alloc] init];
  NSUInteger lastRangeLocation = range.location;
  NSUInteger endLocation = range.location + range.length;

  for (NSUInteger i = range.location; i < endLocation; i++) {
    NSRange currentRange = NSMakeRange(i, 1);
    BOOL forbiddenStyleFound = NO;

    for (id style in activeStyleObjects) {
      if ([style detectStyle:currentRange]) {
        forbiddenStyleFound = YES;
        break;
      }
    }

    if (forbiddenStyleFound) {
      if (i > lastRangeLocation) {
        NSRange cleanRange =
            NSMakeRange(lastRangeLocation, i - lastRangeLocation);
        [newRanges addObject:[NSValue valueWithRange:cleanRange]];
      }
      lastRangeLocation = i + 1;
    }
  }

  if (lastRangeLocation < endLocation) {
    NSRange remainingRange =
        NSMakeRange(lastRangeLocation, endLocation - lastRangeLocation);
    [newRanges addObject:[NSValue valueWithRange:remainingRange]];
  }

  return newRanges;
}

@end
