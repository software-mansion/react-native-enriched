#import "OrderedListMetricsUtils.h"

typedef struct {
  CGFloat digitWidth;
  CGFloat dotWidth;
} OrderedListMarkerMetrics;

static NSMutableDictionary<UIFont *, NSValue *> *markerMetricsCache(void) {
  static NSMutableDictionary<UIFont *, NSValue *> *cache;
  static dispatch_once_t onceToken;
  dispatch_once(&onceToken, ^{
    cache = [NSMutableDictionary dictionary];
  });
  return cache;
}

static OrderedListMarkerMetrics markerMetricsForFont(UIFont *font) {
  NSMutableDictionary<UIFont *, NSValue *> *cache = markerMetricsCache();
  NSValue *cached = cache[font];
  OrderedListMarkerMetrics metrics;
  if (cached != nil) {
    [cached getValue:&metrics];
    return metrics;
  }

  NSDictionary *attrs = @{NSFontAttributeName : font};
  metrics.digitWidth = [@"0" sizeWithAttributes:attrs].width;
  metrics.dotWidth = [@"." sizeWithAttributes:attrs].width;

  cache[font] = [NSValue value:&metrics
                  withObjCType:@encode(OrderedListMarkerMetrics)];
  return metrics;
}

static NSInteger digitCountOf(NSInteger n) {
  NSInteger count = 1;
  NSInteger value = MAX(n, 1);
  while (value >= 10) {
    value /= 10;
    count += 1;
  }
  return count;
}

// counts paragraphs (newline-delimited) within a range that is already known
// to start and end exactly on paragraph boundaries
static NSInteger countParagraphsInRange(NSRange listRange, NSString *text) {
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

@implementation OrderedListMetricsUtils

+ (NSInteger)digitCountOf:(NSInteger)n {
  return digitCountOf(n);
}

+ (CGFloat)headIndentForItemCount:(NSInteger)itemCount
                           config:(EnrichedConfig *)config {
  // we don't want to re-measure each marker's actual
  // width. We estimate the width with cached metrics instead
  OrderedListMarkerMetrics metrics =
      markerMetricsForFont([config orderedListMarkerFont]);

  NSInteger digitCount = digitCountOf(itemCount);
  CGFloat widestMarkerWidth =
      digitCount * metrics.digitWidth + metrics.dotWidth;

  CGFloat markerColumnWidth =
      MAX([config orderedListMarginLeft], widestMarkerWidth);
  return markerColumnWidth + [config orderedListGapWidth];
}

+ (NSRange)contiguousOrderedListRangeContaining:(NSRange)range
                                       forStyle:(OrderedListStyle *)style
                                      itemCount:(NSInteger *)outCount {
  NSString *fullText = style.host.textView.textStorage.string;
  NSUInteger length = fullText.length;
  if (length == 0) {
    if (outCount != nullptr) {
      *outCount = 0;
    }
    return NSMakeRange(range.location, 0);
  }

  NSTextStorage *textStorage = style.host.textView.textStorage;
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
    if (![style detect:NSMakeRange(firstParagraphStart - 1, 0)]) {
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
    if (![style detect:NSMakeRange(lastParagraphEnd, 0)]) {
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
    *outCount = countParagraphsInRange(listRange, fullText);
  }
  return listRange;
}

@end
