#import "EnrichedTextInputView.h"
#import "RangeUtils.h"
#import "StyleHeaders.h"
#import "StyleUtils.h"
#import "TextInsertionUtils.h"

@implementation OrderedListStyle {
  // we don't want to re-measure each marker's actual
  // width. We estimate the width with cached metrics instead
  UIFont *_cachedMarkerFont;
  CGFloat _cachedDigitWidth;
  CGFloat _cachedDotWidth;
}

+ (StyleType)getType {
  return OrderedList;
}

- (NSString *)getValue {
  return @"EnrichedOrderedList";
}

- (BOOL)isParagraph {
  return YES;
}

- (BOOL)needsZWS {
  return YES;
}

- (void)applyStyling:(NSRange)range {
  // lists are drawn manually

  // if the widest counter ("N.") width overflows the initially given margin,
  // we expand that margin. Every item in the same contiguous list must share
  // the same column width, so we expand to the full ordered list occurrence and
  // re-indent all of it - even when only a single paragraph is dirty (e.g. an
  // item was just added)
  NSInteger itemCount = 0;
  NSRange listRange = [self contiguousOrderedListRangeContaining:range
                                                       itemCount:&itemCount];

  [self applyIndentForListRange:listRange itemCount:itemCount];
}

// re-styling is normally run only on dirty-ranges, but a dirty-range
// may change an ordered list structure and those lists need to be
// re-styled. E.g. it happens when we remove an ordered list
// element - it affects the adjacent lists, as their ordinals are different
// and the computed margin might be stale
- (void)recalculateListsAroundEditedRange:(NSRange)range {
  NSUInteger length = self.host.textView.textStorage.string.length;
  NSUInteger start = range.location;
  NSUInteger end = NSMaxRange(range);

  // look for ordered lists in adjacent locations
  NSMutableArray<NSNumber *> *seeds = [NSMutableArray array];
  if (start > 0) {
    [seeds addObject:@(start - 1)];
  }
  [seeds addObject:@(start)];
  [seeds addObject:@(end)];

  // dedupe so each surviving contiguous list is recomputed at most once
  NSMutableArray<NSValue *> *handled = [NSMutableArray array];

  for (NSNumber *seedNum in seeds) {
    NSUInteger seed = seedNum.unsignedIntegerValue;
    if (seed >= length) {
      continue;
    }
    if (![self detect:NSMakeRange(seed, 0)]) {
      continue;
    }

    BOOL alreadyHandled = NO;
    for (NSValue *handledRange in handled) {
      if (NSLocationInRange(seed, [handledRange rangeValue])) {
        alreadyHandled = YES;
        break;
      }
    }
    if (alreadyHandled) {
      continue;
    }

    NSInteger itemCount = 0;
    NSRange listRange =
        [self contiguousOrderedListRangeContaining:NSMakeRange(seed, 0)
                                         itemCount:&itemCount];
    [handled addObject:[NSValue valueWithRange:listRange]];
    [self applyIndentForListRange:listRange itemCount:itemCount];
  }
}

- (void)ensureMarkerMetricsForFont:(UIFont *)font {
  if (_cachedMarkerFont != nil && [_cachedMarkerFont isEqual:font]) {
    return;
  }
  _cachedMarkerFont = font;
  NSDictionary *attrs = @{NSFontAttributeName : font};
  _cachedDigitWidth = [@"0" sizeWithAttributes:attrs].width;
  _cachedDotWidth = [@"." sizeWithAttributes:attrs].width;
}

- (NSInteger)digitCountOf:(NSInteger)n {
  NSInteger count = 1;
  NSInteger value = MAX(n, 1);
  while (value >= 10) {
    value /= 10;
    count += 1;
  }
  return count;
}

// computes the shared marker-column indent for a list of the given item
// count. The largest marker value equals the item count (numbering starts
// at 1); if its width overflows the configured margin we expand to fit it
- (CGFloat)headIndentForItemCount:(NSInteger)itemCount {
  UIFont *markerFont = [self.host.config orderedListMarkerFont];
  [self ensureMarkerMetricsForFont:markerFont];

  NSInteger digitCount = [self digitCountOf:itemCount];
  CGFloat widestMarkerWidth = digitCount * _cachedDigitWidth + _cachedDotWidth;

  CGFloat markerColumnWidth =
      MAX([self.host.config orderedListMarginLeft], widestMarkerWidth);
  return markerColumnWidth + [self.host.config orderedListGapWidth];
}

- (void)applyIndentForListRange:(NSRange)listRange
                      itemCount:(NSInteger)itemCount {
  CGFloat listHeadIndent = [self headIndentForItemCount:itemCount];

  [self.host.textView.textStorage
      enumerateAttribute:NSParagraphStyleAttributeName
                 inRange:listRange
                 options:0
              usingBlock:^(id _Nullable value, NSRange range,
                           BOOL *_Nonnull stop) {
                NSParagraphStyle *existing = (NSParagraphStyle *)value;
                // skip re-styling paragraphs that don't require it
                if (existing != nullptr &&
                    existing.headIndent == listHeadIndent &&
                    existing.firstLineHeadIndent == listHeadIndent) {
                  return;
                }
                NSMutableParagraphStyle *pStyle =
                    existing ? [existing mutableCopy]
                             : [[NSMutableParagraphStyle alloc] init];
                pStyle.headIndent = listHeadIndent;
                pStyle.firstLineHeadIndent = listHeadIndent;
                [self.host.textView.textStorage
                    addAttribute:NSParagraphStyleAttributeName
                           value:pStyle
                           range:range];
              }];
}

- (BOOL)appliesStylingToTyping {
  return YES;
}

- (void)applyStylingToTypingAttrs:(NSMutableDictionary *)attributes {
  NSMutableParagraphStyle *pStyle =
      [attributes[NSParagraphStyleAttributeName] mutableCopy];
  if (pStyle == nil)
    return;

  NSUInteger location = self.host.textView.selectedRange.location;
  NSUInteger length = self.host.textView.textStorage.length;

  NSParagraphStyle *existingStyle = nil;
  if (length > 0) {
    // applying styling to typing attributes always happen after applying
    // the styles, so we can lookup the existing style for the indent
    NSUInteger lookupLocation = MIN(location, length - 1);
    existingStyle =
        [self.host.textView.textStorage attribute:NSParagraphStyleAttributeName
                                          atIndex:lookupLocation
                                   effectiveRange:NULL];
  }

  if (existingStyle) {
    pStyle.headIndent = existingStyle.headIndent;
    pStyle.firstLineHeadIndent = existingStyle.firstLineHeadIndent;
  } else {
    CGFloat fallbackIndent = [self headIndentForItemCount:1];
    pStyle.headIndent = fallbackIndent;
    pStyle.firstLineHeadIndent = fallbackIndent;
  }

  attributes[NSParagraphStyleAttributeName] = pStyle;
}

// walks paragraphs backward and forward from the given range to find the full
// contiguous run of ordered-list items it belongs to, and counts them
- (NSRange)contiguousOrderedListRangeContaining:(NSRange)range
                                      itemCount:(NSInteger *)outCount {
  NSString *fullText = self.host.textView.textStorage.string;
  NSUInteger length = fullText.length;
  if (length == 0) {
    if (outCount != nullptr) {
      *outCount = 0;
    }
    return NSMakeRange(range.location, 0);
  }

  NSTextStorage *textStorage = self.host.textView.textStorage;
  NSRange fullRange = NSMakeRange(0, length);
  NSUInteger seedLocation = MIN(range.location, length - 1);

  NSRange seedRun;
  [textStorage attribute:NSParagraphStyleAttributeName
                    atIndex:seedLocation
      longestEffectiveRange:&seedRun
                    inRange:fullRange];

  NSUInteger firstParagraphStart = seedRun.location;
  NSUInteger lastParagraphEnd = NSMaxRange(seedRun);

  // seek backward over preceding ordered-list runs
  while (firstParagraphStart > 0) {
    if (![self detect:NSMakeRange(firstParagraphStart - 1, 0)]) {
      break;
    }
    NSRange previousRun;
    [textStorage attribute:NSParagraphStyleAttributeName
                      atIndex:firstParagraphStart - 1
        longestEffectiveRange:&previousRun
                      inRange:fullRange];
    firstParagraphStart = previousRun.location;
  }

  // seek forward over following ordered-list runs
  while (lastParagraphEnd < length) {
    if (![self detect:NSMakeRange(lastParagraphEnd, 0)]) {
      break;
    }
    NSRange nextRun;
    [textStorage attribute:NSParagraphStyleAttributeName
                      atIndex:lastParagraphEnd
        longestEffectiveRange:&nextRun
                      inRange:fullRange];
    lastParagraphEnd = NSMaxRange(nextRun);
  }

  NSRange listRange =
      NSMakeRange(firstParagraphStart, lastParagraphEnd - firstParagraphStart);

  if (outCount != nullptr) {
    *outCount =
        [self countParagraphsInRange:listRange
                              inText:self.host.textView.textStorage.string];
  }
  return listRange;
}

// counts paragraphs (newline-delimited) within a range that is already known
// to start and end exactly on paragraph boundaries
- (NSInteger)countParagraphsInRange:(NSRange)listRange inText:(NSString *)text {
  if (listRange.length == 0) {
    return 0;
  }

  NSCharacterSet *newlineSet = [NSCharacterSet newlineCharacterSet];
  NSUInteger rangeEnd = NSMaxRange(listRange);
  NSUInteger cursor = listRange.location;
  NSInteger count = 0;

  while (cursor < rangeEnd) {
    count += 1;
    NSRange newline =
        [text rangeOfCharacterFromSet:newlineSet
                              options:0
                                range:NSMakeRange(cursor, rangeEnd - cursor)];
    cursor = newline.location != NSNotFound ? NSMaxRange(newline) : rangeEnd;
  }

  return count;
}

@end
