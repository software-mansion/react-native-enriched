#import "LayoutManagerExtension.h"
#import "ColorExtension.h"
#import "EnrichedViewHost.h"
#import "RangeUtils.h"
#import "StyleHeaders.h"
#import "WeakBox.h"
#import <objc/runtime.h>

@implementation NSLayoutManager (LayoutManagerExtension)

static void const *kInputKey = &kInputKey;

- (id)input {
  WeakBox *box = objc_getAssociatedObject(self, kInputKey);
  return box.value;
}

- (void)setInput:(id)value {
  WeakBox *box = [WeakBox new];
  box.value = value;
  objc_setAssociatedObject(self, kInputKey, box,
                           OBJC_ASSOCIATION_RETAIN_NONATOMIC);
}

+ (void)load {
  static dispatch_once_t onceToken;
  dispatch_once(&onceToken, ^{
    Class myClass = [NSLayoutManager class];
    SEL originalSelector = @selector(drawBackgroundForGlyphRange:atPoint:);
    SEL swizzledSelector = @selector(my_drawBackgroundForGlyphRange:atPoint:);
    Method originalMethod = class_getInstanceMethod(myClass, originalSelector);
    Method swizzledMethod = class_getInstanceMethod(myClass, swizzledSelector);

    BOOL didAddMethod = class_addMethod(
        myClass, originalSelector, method_getImplementation(swizzledMethod),
        method_getTypeEncoding(swizzledMethod));

    if (didAddMethod) {
      class_replaceMethod(myClass, swizzledSelector,
                          method_getImplementation(originalMethod),
                          method_getTypeEncoding(originalMethod));
    } else {
      method_exchangeImplementations(originalMethod, swizzledMethod);
    }
  });
}

- (void)my_drawBackgroundForGlyphRange:(NSRange)glyphRange
                               atPoint:(CGPoint)origin {
  [self my_drawBackgroundForGlyphRange:glyphRange atPoint:origin];

  id<EnrichedViewHost> host = self.input;
  if (host == nullptr) {
    return;
  }

  NSRange visibleCharRange = [self characterRangeForGlyphRange:glyphRange
                                              actualGlyphRange:NULL];

  [self drawBlockQuotes:host origin:origin visibleCharRange:visibleCharRange];
  [self drawLists:host origin:origin visibleCharRange:visibleCharRange];
  [self drawCodeBlocks:host origin:origin visibleCharRange:visibleCharRange];
}

- (void)drawCodeBlocks:(id<EnrichedViewHost>)host
                origin:(CGPoint)origin
      visibleCharRange:(NSRange)visibleCharRange {
  CodeBlockStyle *codeBlockStyle = host.stylesDict[@([CodeBlockStyle getType])];
  if (codeBlockStyle == nullptr) {
    return;
  }

  NSArray<StylePair *> *allCodeBlocks = [codeBlockStyle all:visibleCharRange];
  NSArray<StylePair *> *mergedCodeBlocks =
      [self mergeContiguousStylePairs:allCodeBlocks];
  UIColor *bgColor =
      [[host.config codeBlockBgColor] colorWithAlphaIfNotTransparent:0.4];
  CGFloat radius = [host.config codeBlockBorderRadius];
  [bgColor setFill];

  for (StylePair *pair in mergedCodeBlocks) {
    NSRange blockCharacterRange = [pair.rangeValue rangeValue];
    if (blockCharacterRange.length == 0)
      continue;

    NSArray *paragraphs =
        [RangeUtils getSeparateParagraphsRangesIn:host.textView
                                            range:blockCharacterRange];
    if (paragraphs.count == 0)
      continue;

    NSRange firstParagraphRange =
        [((NSValue *)[paragraphs firstObject]) rangeValue];
    NSRange lastParagraphRange =
        [((NSValue *)[paragraphs lastObject]) rangeValue];

    for (NSValue *paragraphValue in paragraphs) {
      NSRange paragraphCharacterRange = [paragraphValue rangeValue];

      BOOL isFirstParagraph =
          NSEqualRanges(paragraphCharacterRange, firstParagraphRange);
      BOOL isLastParagraph =
          NSEqualRanges(paragraphCharacterRange, lastParagraphRange);

      NSRange paragraphGlyphRange =
          [self glyphRangeForCharacterRange:paragraphCharacterRange
                       actualCharacterRange:NULL];

      __block BOOL isFirstLineOfParagraph = YES;

      [self
          enumerateLineFragmentsForGlyphRange:paragraphGlyphRange
                                   usingBlock:^(
                                       CGRect rect, CGRect usedRect,
                                       NSTextContainer *_Nonnull textContainer,
                                       NSRange glyphRange,
                                       BOOL *_Nonnull stop) {
                                     CGRect lineBgRect = rect;
                                     lineBgRect.origin.x = origin.x;
                                     lineBgRect.origin.y += origin.y;
                                     lineBgRect.size.width =
                                         textContainer.size.width;

                                     UIRectCorner cornersForThisLine = 0;

                                     if (isFirstParagraph &&
                                         isFirstLineOfParagraph) {
                                       cornersForThisLine =
                                           UIRectCornerTopLeft |
                                           UIRectCornerTopRight;
                                     }

                                     BOOL isLastLineOfParagraph =
                                         (NSMaxRange(glyphRange) >=
                                          NSMaxRange(paragraphGlyphRange));

                                     if (isLastParagraph &&
                                         isLastLineOfParagraph) {
                                       cornersForThisLine =
                                           cornersForThisLine |
                                           UIRectCornerBottomLeft |
                                           UIRectCornerBottomRight;
                                     }

                                     UIBezierPath *path = [UIBezierPath
                                         bezierPathWithRoundedRect:lineBgRect
                                                 byRoundingCorners:
                                                     cornersForThisLine
                                                       cornerRadii:CGSizeMake(
                                                                       radius,
                                                                       radius)];
                                     [path fill];

                                     isFirstLineOfParagraph = NO;
                                   }];
    }
  }
}

- (NSArray<StylePair *> *)mergeContiguousStylePairs:
    (NSArray<StylePair *> *)pairs {
  if (pairs.count == 0) {
    return @[];
  }

  NSMutableArray<StylePair *> *mergedPairs = [[NSMutableArray alloc] init];
  StylePair *currentPair = pairs[0];
  NSRange currentRange = [currentPair.rangeValue rangeValue];
  for (NSUInteger i = 1; i < pairs.count; i++) {
    StylePair *nextPair = pairs[i];
    NSRange nextRange = [nextPair.rangeValue rangeValue];

    // The Gap Check:
    // NSMaxRange(currentRange) is where the current block ends.
    // nextRange.location is where the next block starts.
    if (NSMaxRange(currentRange) == nextRange.location) {
      // They touch perfectly (no gap). Merge them.
      currentRange.length += nextRange.length;
    } else {
      // There is a gap (indices don't match).
      // 1. Save the finished block.
      StylePair *mergedPair = [[StylePair alloc] init];
      mergedPair.rangeValue = [NSValue valueWithRange:currentRange];
      mergedPair.styleValue = currentPair.styleValue;
      [mergedPairs addObject:mergedPair];

      // 2. Start a brand new block.
      currentPair = nextPair;
      currentRange = nextRange;
    }
  }

  // Add the final block
  StylePair *lastPair = [[StylePair alloc] init];
  lastPair.rangeValue = [NSValue valueWithRange:currentRange];
  lastPair.styleValue = currentPair.styleValue;
  [mergedPairs addObject:lastPair];

  return mergedPairs;
}

- (void)drawBlockQuotes:(id<EnrichedViewHost>)host
                 origin:(CGPoint)origin
       visibleCharRange:(NSRange)visibleCharRange {
  BlockQuoteStyle *bqStyle = host.stylesDict[@([BlockQuoteStyle getType])];
  if (bqStyle == nullptr) {
    return;
  }

  NSArray *allBlockquotes = [bqStyle all:visibleCharRange];

  for (StylePair *pair in allBlockquotes) {
    NSRange paragraphRange = [host.textView.textStorage.string
        paragraphRangeForRange:[pair.rangeValue rangeValue]];
    NSRange paragraphGlyphRange =
        [self glyphRangeForCharacterRange:paragraphRange
                     actualCharacterRange:nullptr];
    [self
        enumerateLineFragmentsForGlyphRange:paragraphGlyphRange
                                 usingBlock:^(
                                     CGRect rect, CGRect usedRect,
                                     NSTextContainer *_Nonnull textContainer,
                                     NSRange glyphRange, BOOL *_Nonnull stop) {
                                   CGFloat paddingLeft = origin.x;
                                   CGFloat paddingTop = origin.y;
                                   CGFloat x = paddingLeft;
                                   CGFloat y = paddingTop + rect.origin.y;
                                   CGFloat width =
                                       [host.config blockquoteBorderWidth];
                                   CGFloat height = rect.size.height;

                                   CGRect lineRect =
                                       CGRectMake(x, y, width, height);
                                   [[host.config blockquoteBorderColor]
                                       setFill];
                                   UIRectFill(lineRect);
                                 }];
  }
}

- (void)drawLists:(id<EnrichedViewHost>)host
              origin:(CGPoint)origin
    visibleCharRange:(NSRange)visibleCharRange {
  UnorderedListStyle *ulStyle =
      host.stylesDict[@([UnorderedListStyle getType])];
  OrderedListStyle *olStyle = host.stylesDict[@([OrderedListStyle getType])];
  CheckboxListStyle *cbStyle = host.stylesDict[@([CheckboxListStyle getType])];
  if (ulStyle == nullptr || olStyle == nullptr || cbStyle == nullptr) {
    return;
  }

  NSMutableArray *allLists = [[NSMutableArray alloc] init];

  [allLists addObjectsFromArray:[ulStyle all:visibleCharRange]];
  [allLists addObjectsFromArray:[olStyle all:visibleCharRange]];
  [allLists addObjectsFromArray:[cbStyle all:visibleCharRange]];

  for (StylePair *pair in allLists) {
    NSParagraphStyle *pStyle = (NSParagraphStyle *)pair.styleValue;
    NSDictionary *markerAttributes = @{
      NSFontAttributeName : [host.config orderedListMarkerFont],
      NSForegroundColorAttributeName : [host.config orderedListMarkerColor]
    };

    NSArray *paragraphs =
        [RangeUtils getSeparateParagraphsRangesIn:host.textView
                                            range:[pair.rangeValue rangeValue]];

    for (NSValue *paragraph in paragraphs) {
      NSRange paragraphGlyphRange =
          [self glyphRangeForCharacterRange:[paragraph rangeValue]
                       actualCharacterRange:nullptr];

      [self
          enumerateLineFragmentsForGlyphRange:paragraphGlyphRange
                                   usingBlock:^(CGRect rect, CGRect usedRect,
                                                NSTextContainer *container,
                                                NSRange lineGlyphRange,
                                                BOOL *stop) {
                                     NSUInteger charIdx =
                                         [self characterIndexForGlyphAtIndex:
                                                   lineGlyphRange.location];
                                     UIFont *font = [host.textView.textStorage
                                              attribute:NSFontAttributeName
                                                atIndex:charIdx
                                         effectiveRange:nil];
                                     CGRect textUsedRect =
                                         [self getTextAlignedUsedRect:usedRect
                                                                 font:font];

                                     NSString *markerFormat =
                                         pStyle.textLists.firstObject
                                             .markerFormat;

                                     if ([markerFormat
                                             isEqualToString:
                                                 @"EnrichedOrderedList"]) {
                                       NSString *marker = [self
                                           getDecimalMarkerForList:host
                                                         charIndex:charIdx];
                                       [self drawDecimal:host
                                                     marker:marker
                                           markerAttributes:markerAttributes
                                                     origin:origin
                                                   usedRect:usedRect];
                                     } else if ([markerFormat
                                                    isEqualToString:
                                                        @"EnrichedUnorderedLis"
                                                        @"t"]) {
                                       [self drawBullet:host
                                                 origin:origin
                                               usedRect:textUsedRect];
                                     } else if ([markerFormat
                                                    hasPrefix:
                                                        @"EnrichedCheckbox"]) {
                                       [self drawCheckbox:host
                                             markerFormat:markerFormat
                                                   origin:origin
                                                 usedRect:textUsedRect];
                                     }
                                     // only first line of a list gets its
                                     // marker drawn
                                     *stop = YES;
                                   }];
    }
  }
}

- (NSString *)getDecimalMarkerForList:(id<EnrichedViewHost>)host
                            charIndex:(NSUInteger)index {
  NSString *fullText = host.textView.textStorage.string;
  NSInteger itemNumber = 1;

  NSRange currentParagraph =
      [fullText paragraphRangeForRange:NSMakeRange(index, 0)];
  if (currentParagraph.location > 0) {
    OrderedListStyle *olStyle = host.stylesDict[@([OrderedListStyle getType])];

    NSInteger prevParagraphsCount = 0;
    NSInteger recentParagraphLocation =
        [fullText paragraphRangeForRange:NSMakeRange(
                                             currentParagraph.location - 1, 0)]
            .location;

    // seek for previous lists
    while (true) {
      if ([olStyle detect:NSMakeRange(recentParagraphLocation, 0)]) {
        prevParagraphsCount += 1;

        if (recentParagraphLocation > 0) {
          recentParagraphLocation =
              [fullText
                  paragraphRangeForRange:NSMakeRange(
                                             recentParagraphLocation - 1, 0)]
                  .location;
        } else {
          break;
        }
      } else {
        break;
      }
    }

    itemNumber = prevParagraphsCount + 1;
  }

  return [NSString stringWithFormat:@"%ld.", (long)(itemNumber)];
}

// Returns a usedRect adjusted to cover only the text portion of the line.
// When minimumLineHeight expands the line box, extra space is added at the top
// and text stays at the bottom. This strips that padding so markers align with
// the text, not the full line box.
- (CGRect)getTextAlignedUsedRect:(CGRect)usedRect font:(UIFont *)font {
  if (font && usedRect.size.height > font.lineHeight) {
    CGFloat extraSpace = usedRect.size.height - font.lineHeight;
    usedRect.origin.y += extraSpace;
    usedRect.size.height = font.lineHeight;
  }
  return usedRect;
}

- (void)drawCheckbox:(id<EnrichedViewHost>)host
        markerFormat:(NSString *)markerFormat
              origin:(CGPoint)origin
            usedRect:(CGRect)usedRect {
  BOOL isChecked = [markerFormat isEqualToString:@"EnrichedCheckbox1"];

  UIImage *image = isChecked ? host.config.checkboxCheckedImage
                             : host.config.checkboxUncheckedImage;
  CGFloat gapWidth = [host.config checkboxListGapWidth];
  CGFloat boxSize = [host.config checkboxListBoxSize];

  CGFloat centerY = CGRectGetMidY(usedRect) + origin.y;
  CGFloat boxX = origin.x + usedRect.origin.x - gapWidth - boxSize;
  CGFloat boxY = centerY - boxSize / 2.0;

  [image drawAtPoint:CGPointMake(boxX, boxY)];
}

- (void)drawBullet:(id<EnrichedViewHost>)host
            origin:(CGPoint)origin
          usedRect:(CGRect)usedRect {
  CGFloat gapWidth = [host.config unorderedListGapWidth];
  CGFloat bulletSize = [host.config unorderedListBulletSize];
  CGFloat bulletX = origin.x + usedRect.origin.x - gapWidth - bulletSize / 2;
  CGFloat centerY = CGRectGetMidY(usedRect) + origin.y;

  CGContextRef context = UIGraphicsGetCurrentContext();
  CGContextSaveGState(context);
  {
    [[host.config unorderedListBulletColor] setFill];
    CGContextAddArc(context, bulletX, centerY, bulletSize / 2, 0, 2 * M_PI,
                    YES);
    CGContextFillPath(context);
  }
  CGContextRestoreGState(context);
}

- (void)drawDecimal:(id<EnrichedViewHost>)host
              marker:(NSString *)marker
    markerAttributes:(NSDictionary *)markerAttributes
              origin:(CGPoint)origin
            usedRect:(CGRect)usedRect {
  CGFloat gapWidth = [host.config orderedListGapWidth];
  CGSize markerSize = [marker sizeWithAttributes:markerAttributes];
  CGFloat markerX = usedRect.origin.x - gapWidth - markerSize.width / 2;
  CGFloat centerY = CGRectGetMidY(usedRect) + origin.y;
  CGFloat markerY = centerY - markerSize.height / 2.0;

  [marker drawAtPoint:CGPointMake(markerX, markerY)
       withAttributes:markerAttributes];
}

@end
