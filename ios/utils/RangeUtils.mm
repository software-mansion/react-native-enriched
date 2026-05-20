#import "RangeUtils.h"

@implementation RangeUtils

+ (NSArray *)getSeparateParagraphsRangesIn:(UITextView *)textView
                                     range:(NSRange)range {
  // just in case, get full paragraphs range
  NSRange fullRange =
      [textView.textStorage.string paragraphRangeForRange:range];

  // we are in an empty paragraph
  if (fullRange.length == 0) {
    return @[ [NSValue valueWithRange:fullRange] ];
  }

  NSMutableArray *results = [[NSMutableArray alloc] init];

  NSInteger lastStart = fullRange.location;
  for (int i = int(fullRange.location);
       i < fullRange.location + fullRange.length; i++) {
    unichar currentChar = [textView.textStorage.string characterAtIndex:i];
    if ([[NSCharacterSet newlineCharacterSet] characterIsMember:currentChar]) {
      NSRange paragraphRange = [textView.textStorage.string
          paragraphRangeForRange:NSMakeRange(lastStart, i - lastStart)];
      [results addObject:[NSValue valueWithRange:paragraphRange]];
      lastStart = i + 1;
    }
  }

  if (lastStart < fullRange.location + fullRange.length) {
    NSRange paragraphRange = [textView.textStorage.string
        paragraphRangeForRange:NSMakeRange(lastStart, fullRange.location +
                                                          fullRange.length -
                                                          lastStart)];
    [results addObject:[NSValue valueWithRange:paragraphRange]];
  }

  return results;
}

+ (NSArray *)getNonNewlineRangesIn:(UITextView *)textView range:(NSRange)range {
  NSMutableArray *nonNewlineRanges = [[NSMutableArray alloc] init];
  int lastRangeLocation = int(range.location);

  for (int i = int(range.location); i < range.location + range.length; i++) {
    unichar currentChar = [textView.textStorage.string characterAtIndex:i];
    if ([[NSCharacterSet newlineCharacterSet] characterIsMember:currentChar]) {
      if (i - lastRangeLocation > 0) {
        [nonNewlineRanges
            addObject:[NSValue
                          valueWithRange:NSMakeRange(lastRangeLocation,
                                                     i - lastRangeLocation)]];
      }
      lastRangeLocation = i + 1;
    }
  }
  if (lastRangeLocation < range.location + range.length) {
    [nonNewlineRanges
        addObject:[NSValue
                      valueWithRange:NSMakeRange(lastRangeLocation,
                                                 range.location + range.length -
                                                     lastRangeLocation)]];
  }

  return nonNewlineRanges;
}

// Condenses an array of NSRange to make sure the overlapping ones are connected
// + sorted based on NSRange.location
+ (NSArray *)connectAndDedupeRanges:(NSArray *)ranges {
  if (ranges.count == 0) {
    return @[];
  }

  // We sort primarily by location. If locations match, shorter length goes
  // first
  NSArray<NSValue *> *sortedRanges =
      [ranges sortedArrayUsingComparator:^NSComparisonResult(NSValue *obj1,
                                                             NSValue *obj2) {
        NSRange range1 = obj1.rangeValue;
        NSRange range2 = obj2.rangeValue;

        if (range1.location < range2.location)
          return NSOrderedAscending;
        if (range1.location > range2.location)
          return NSOrderedDescending;

        if (range1.length < range2.length)
          return NSOrderedAscending;
        if (range1.length > range2.length)
          return NSOrderedDescending;

        return NSOrderedSame;
      }];

  NSMutableArray<NSValue *> *mergedRanges = [[NSMutableArray alloc] init];

  // We work by comparing each two ranges.
  // If we connected some ranges, the newly created one is still compared with
  // the next ranges from the sorted list.
  NSRange currentRange = sortedRanges[0].rangeValue;

  for (NSUInteger i = 1; i < sortedRanges.count; i++) {
    NSRange nextRange = sortedRanges[i].rangeValue;

    // Calculate the end points
    NSUInteger currentMax = currentRange.location + currentRange.length;
    NSUInteger nextMax = nextRange.location + nextRange.length;

    // If next range starts before (or exactly when) the current one ends.
    if (nextRange.location <= currentMax) {
      // Merge them; the new end is the maximum of the two ends
      NSUInteger newMax = MAX(currentMax, nextMax);
      currentRange.length = newMax - currentRange.location;
    } else {
      // No overlap; push the current range and start a new one
      [mergedRanges addObject:[NSValue valueWithRange:currentRange]];
      currentRange = nextRange;
    }
  }

  // Add the final range
  [mergedRanges addObject:[NSValue valueWithRange:currentRange]];

  return [mergedRanges copy];
}

// Updates a list of NSRanges based on a text change, so that they are still
// pointing to the same characters. editedRange is the post-change range of the
// edited fragment. delta tells what is the length change of the edited
// fragment. While the ranges outside of the change are being just shifted, the
// ones intersecting with it are just merging with the change.
+ (NSArray *)shiftRanges:(NSArray *)ranges
         withEditedRange:(NSRange)editedRange
          changeInLength:(NSInteger)delta {
  NSMutableArray *result = [[NSMutableArray alloc] init];

  // Calculate what the changed range was like before being edited
  NSUInteger oldEditLength = editedRange.length - delta;
  NSUInteger oldEditEnd = editedRange.location + oldEditLength;

  NSUInteger newEditEnd = editedRange.location + editedRange.length;

  for (NSValue *value in ranges) {
    NSRange range = [value rangeValue];
    NSUInteger rangeEnd = range.location + range.length;

    if (rangeEnd <= editedRange.location) {
      // Range was strictly before the old edit range.
      // Do nothing.
      [result addObject:value];
    } else if (range.location >= oldEditEnd) {
      // Range was strictly after the old edit range.
      // Shift it by the delta.
      [result
          addObject:[NSValue valueWithRange:NSMakeRange(range.location + delta,
                                                        range.length)]];
    } else {
      // Range overlaps the old edit range in some way.
      // Our best bet is to merge it with the edit range.

      NSUInteger newStart = MIN(range.location, editedRange.location);

      NSUInteger newEnd;
      if (rangeEnd <= oldEditEnd) {
        // The range was inside the editedRange before.
        // So we use the newer editRange as the end here.
        newEnd = newEditEnd;
      } else {
        // The range sticked outside of the editedRange before.
        // It is safe to shift its end and use it.
        newEnd = rangeEnd + delta;
      }

      NSRange adjustedRange = NSMakeRange(newStart, newEnd - newStart);
      [result addObject:[NSValue valueWithRange:adjustedRange]];
    }
  }

  return result;
}

@end
