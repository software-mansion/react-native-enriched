#import "OccurenceUtils.h"

@interface OccurenceUtils ()
+ (void)enumerateAttributes:(NSArray<NSAttributedStringKey> *)keys
                   inString:(NSAttributedString *)string
                    inRange:(NSRange)range
                  withBlock:(void(NS_NOESCAPE ^)(NSAttributedStringKey key,
                                                 id value, NSRange range,
                                                 BOOL *stop))block;

+ (NSArray<StylePair *> *)
    collectAttributes:(NSArray<NSAttributedStringKey> *)keys
             inString:(NSAttributedString *)string
              inRange:(NSRange)range
        withCondition:(BOOL(NS_NOESCAPE ^)(id value, NSRange range))condition;
@end

@implementation OccurenceUtils

+ (void)enumerateAttributes:(NSArray<NSAttributedStringKey> *)keys
                   inString:(NSAttributedString *)string
                    inRange:(NSRange)range
                  withBlock:(void(NS_NOESCAPE ^)(NSAttributedStringKey key,
                                                 id value, NSRange range,
                                                 BOOL *stop))block {
  __block BOOL outerStop = NO;

  for (NSAttributedStringKey key in keys) {

    [string enumerateAttribute:key
                       inRange:range
                       options:0
                    usingBlock:^(id value, NSRange subRange, BOOL *innerStop) {
                      block(key, value, subRange, &outerStop);
                      if (outerStop) {
                        *innerStop = YES;
                      }
                    }];

    if (outerStop)
      break;
  }
}

+ (NSArray<StylePair *> *)
    collectAttributes:(NSArray<NSAttributedStringKey> *)keys
             inString:(NSAttributedString *)string
              inRange:(NSRange)range
        withCondition:(BOOL(NS_NOESCAPE ^)(id value, NSRange range))condition {
  NSMutableArray<StylePair *> *result = [NSMutableArray array];

  [self enumerateAttributes:keys
                   inString:string
                    inRange:range
                  withBlock:^(NSAttributedStringKey key, id value,
                              NSRange attrRange, BOOL *stop) {
                    if (condition(value, attrRange)) {
                      StylePair *pair = [StylePair new];
                      pair.rangeValue = [NSValue valueWithRange:attrRange];
                      pair.styleValue = value;
                      [result addObject:pair];
                    }
                  }];

  return result;
}

#pragma mark - ============================================================
#pragma mark Public API (Attributed String Versions)
#pragma mark - ============================================================

+ (BOOL)detect:(NSAttributedStringKey)key
         inString:(NSAttributedString *)string
          inRange:(NSRange)range
    withCondition:(BOOL(NS_NOESCAPE ^)(id value, NSRange range))condition {
  __block NSInteger total = 0;

  [self enumerateAttributes:@[ key ]
                   inString:string
                    inRange:range
                  withBlock:^(NSAttributedStringKey key, id value, NSRange r,
                              BOOL *stop) {
                    if (condition(value, r)) {
                      total += r.length;
                    }
                  }];

  return total == range.length;
}

+ (BOOL)detectMultiple:(NSArray<NSAttributedStringKey> *)keys
              inString:(NSAttributedString *)string
               inRange:(NSRange)range
         withCondition:(BOOL(NS_NOESCAPE ^)(id value, NSRange range))condition {
  __block NSInteger total = 0;

  [self enumerateAttributes:keys
                   inString:string
                    inRange:range
                  withBlock:^(NSAttributedStringKey key, id value, NSRange r,
                              BOOL *stop) {
                    if (condition(value, r)) {
                      total += r.length;
                    }
                  }];

  return total == range.length;
}

+ (BOOL)any:(NSAttributedStringKey)key
         inString:(NSAttributedString *)string
          inRange:(NSRange)range
    withCondition:(BOOL(NS_NOESCAPE ^)(id value, NSRange range))condition {
  __block BOOL found = NO;

  [self enumerateAttributes:@[ key ]
                   inString:string
                    inRange:range
                  withBlock:^(NSAttributedStringKey key, id value, NSRange r,
                              BOOL *stop) {
                    if (condition(value, r)) {
                      found = YES;
                      *stop = YES;
                    }
                  }];

  return found;
}

+ (BOOL)anyMultiple:(NSArray<NSAttributedStringKey> *)keys
           inString:(NSAttributedString *)string
            inRange:(NSRange)range
      withCondition:(BOOL(NS_NOESCAPE ^)(id value, NSRange range))condition {
  __block BOOL found = NO;

  [self enumerateAttributes:keys
                   inString:string
                    inRange:range
                  withBlock:^(NSAttributedStringKey key, id value, NSRange r,
                              BOOL *stop) {
                    if (condition(value, r)) {
                      found = YES;
                      *stop = YES;
                    }
                  }];

  return found;
}

+ (NSArray<StylePair *> *)all:(NSAttributedStringKey)key
                     inString:(NSAttributedString *)string
                      inRange:(NSRange)range
                withCondition:(BOOL(NS_NOESCAPE ^)(id value, NSRange range))
                                  condition {
  return [self collectAttributes:@[ key ]
                        inString:string
                         inRange:range
                   withCondition:condition];
}

+ (NSArray<StylePair *> *)allMultiple:(NSArray<NSAttributedStringKey> *)keys
                             inString:(NSAttributedString *)string
                              inRange:(NSRange)range
                        withCondition:
                            (BOOL(NS_NOESCAPE ^)(id value, NSRange range))
                                condition {
  return [self collectAttributes:keys
                        inString:string
                         inRange:range
                   withCondition:condition];
}

#pragma mark - ============================================================
#pragma mark Public API (EnrichedTextInputView Versions)
#pragma mark - ============================================================

/// detects on a range using input->textView.textStorage
+ (BOOL)detect:(NSAttributedStringKey)key
        withInput:(EnrichedTextInputView *)input
          inRange:(NSRange)range
    withCondition:(BOOL(NS_NOESCAPE ^)(id value, NSRange range))condition {
  return [self detect:key
             inString:input->textView.textStorage
              inRange:range
        withCondition:condition];
}

/// detects at index (typing attributes logic preserved)
+ (BOOL)detect:(NSAttributedStringKey)key
        withInput:(EnrichedTextInputView *)input
          atIndex:(NSUInteger)index
    checkPrevious:(BOOL)checkPrev
    withCondition:(BOOL(NS_NOESCAPE ^)(id value, NSRange range))condition {
  NSRange detectionRange = NSMakeRange(index, 0);
  id attrValue;

  if (NSEqualRanges(input->textView.selectedRange, detectionRange)) {
    attrValue = input->textView.typingAttributes[key];

  } else if (index == input->textView.textStorage.string.length) {

    if (checkPrev) {
      NSRange paragraph = [input->textView.textStorage.string
          paragraphRangeForRange:detectionRange];
      if (paragraph.location == detectionRange.location) {
        return NO;
      } else {
        return [self detect:key
                  withInput:input
                    inRange:NSMakeRange(paragraph.location, 1)
              withCondition:condition];
      }
    } else {
      return NO;
    }

  } else {
    NSRange eff;
    attrValue = [input->textView.textStorage attribute:key
                                               atIndex:index
                                        effectiveRange:&eff];
  }

  return condition(attrValue, detectionRange);
}

+ (BOOL)detectMultiple:(NSArray<NSAttributedStringKey> *)keys
             withInput:(EnrichedTextInputView *)input
               inRange:(NSRange)range
         withCondition:(BOOL(NS_NOESCAPE ^)(id value, NSRange range))condition {
  return [self detectMultiple:keys
                     inString:input->textView.textStorage
                      inRange:range
                withCondition:condition];
}

+ (BOOL)any:(NSAttributedStringKey)key
        withInput:(EnrichedTextInputView *)input
          inRange:(NSRange)range
    withCondition:(BOOL(NS_NOESCAPE ^)(id value, NSRange range))condition {
  return [self any:key
           inString:input->textView.textStorage
            inRange:range
      withCondition:condition];
}

+ (BOOL)anyMultiple:(NSArray<NSAttributedStringKey> *)keys
          withInput:(EnrichedTextInputView *)input
            inRange:(NSRange)range
      withCondition:(BOOL(NS_NOESCAPE ^)(id value, NSRange range))condition {
  return [self anyMultiple:keys
                  inString:input->textView.textStorage
                   inRange:range
             withCondition:condition];
}

+ (NSArray<StylePair *> *)all:(NSAttributedStringKey)key
                    withInput:(EnrichedTextInputView *)input
                      inRange:(NSRange)range
                withCondition:(BOOL(NS_NOESCAPE ^)(id value, NSRange range))
                                  condition {
  return [self all:key
           inString:input->textView.textStorage
            inRange:range
      withCondition:condition];
}

+ (NSArray<StylePair *> *)allMultiple:(NSArray<NSAttributedStringKey> *)keys
                            withInput:(EnrichedTextInputView *)input
                              inRange:(NSRange)range
                        withCondition:
                            (BOOL(NS_NOESCAPE ^)(id value, NSRange range))
                                condition {
  return [self allMultiple:keys
                  inString:input->textView.textStorage
                   inRange:range
             withCondition:condition];
}

+ (NSArray *)getRangesWithout:(NSArray<NSNumber *> *)types
                    withInput:(EnrichedTextInputView *)input
                      inRange:(NSRange)range {
  NSMutableArray *activeStyles = [NSMutableArray array];

  for (NSNumber *type in types) {
    id<BaseStyleProtocol> style = input->stylesDict[type];
    [activeStyles addObject:style];
  }

  if (activeStyles.count == 0) {
    return @[ [NSValue valueWithRange:range] ];
  }

  NSMutableArray<NSValue *> *newRanges = [NSMutableArray array];
  NSUInteger lastLocation = range.location;
  NSUInteger end = range.location + range.length;

  for (NSUInteger i = range.location; i < end; i++) {

    BOOL forbidden = NO;
    for (id style in activeStyles) {
      if ([style detectStyle:NSMakeRange(i, 1)]) {
        forbidden = YES;
        break;
      }
    }

    if (forbidden) {
      if (i > lastLocation) {
        [newRanges
            addObject:[NSValue valueWithRange:NSMakeRange(lastLocation,
                                                          i - lastLocation)]];
      }
      lastLocation = i + 1;
    }
  }

  if (lastLocation < end) {
    [newRanges
        addObject:[NSValue valueWithRange:NSMakeRange(lastLocation,
                                                      end - lastLocation)]];
  }

  return newRanges;
}

@end
