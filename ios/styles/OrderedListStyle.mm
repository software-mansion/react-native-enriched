#import "EnrichedTextInputView.h"
#import "OrderedListMetricsUtils.h"
#import "RangeUtils.h"
#import "StyleHeaders.h"
#import "StyleUtils.h"
#import "TextInsertionUtils.h"

@implementation OrderedListStyle

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
  NSRange listRange =
      [OrderedListMetricsUtils contiguousOrderedListRangeContaining:range
                                                           forStyle:self
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
    NSRange listRange = [OrderedListMetricsUtils
        contiguousOrderedListRangeContaining:NSMakeRange(seed, 0)
                                    forStyle:self
                                   itemCount:&itemCount];
    [handled addObject:[NSValue valueWithRange:listRange]];
    [self applyIndentForListRange:listRange itemCount:itemCount];
  }
}

- (void)applyIndentForListRange:(NSRange)listRange
                      itemCount:(NSInteger)itemCount {
  CGFloat listHeadIndent =
      [OrderedListMetricsUtils headIndentForItemCount:itemCount
                                               config:self.host.config];

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
    CGFloat fallbackIndent =
        [OrderedListMetricsUtils headIndentForItemCount:1
                                                 config:self.host.config];
    pStyle.headIndent = fallbackIndent;
    pStyle.firstLineHeadIndent = fallbackIndent;
  }

  attributes[NSParagraphStyleAttributeName] = pStyle;
}

@end
