#import "ParagraphsUtils.h"

@implementation ParagraphsUtils

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
  for (int i = fullRange.location; i < fullRange.location + fullRange.length;
       i++) {
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
  int lastRangeLocation = range.location;

  for (int i = range.location; i < range.location + range.length; i++) {
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

+ (NSArray *)getSeparateParagraphsRangesInAttributedString:
                 (NSAttributedString *)attributedString
                                                     range:(NSRange)range {
  // just in case, get full paragraphs range
  NSRange fullRange = [attributedString.string paragraphRangeForRange:range];

  // we are in an empty paragraph
  if (fullRange.length == 0) {
    return @[ [NSValue valueWithRange:fullRange] ];
  }

  NSMutableArray *results = [[NSMutableArray alloc] init];

  NSInteger lastStart = fullRange.location;
  for (int i = fullRange.location; i < fullRange.location + fullRange.length;
       i++) {
    unichar currentChar = [attributedString.string characterAtIndex:i];
    if ([[NSCharacterSet newlineCharacterSet] characterIsMember:currentChar]) {
      NSRange paragraphRange = [attributedString.string
          paragraphRangeForRange:NSMakeRange(lastStart, i - lastStart)];
      [results addObject:[NSValue valueWithRange:paragraphRange]];
      lastStart = i + 1;
    }
  }

  if (lastStart < fullRange.location + fullRange.length) {
    NSRange paragraphRange = [attributedString.string
        paragraphRangeForRange:NSMakeRange(lastStart, fullRange.location +
                                                          fullRange.length -
                                                          lastStart)];
    [results addObject:[NSValue valueWithRange:paragraphRange]];
  }

  return results;
}

+ (NSArray *)getNonNewlineRangesInAttributedString:
                 (NSAttributedString *)attributedString
                                             range:(NSRange)range {
  NSMutableArray *nonNewlineRanges = [[NSMutableArray alloc] init];
  int lastRangeLocation = range.location;

  for (int i = range.location; i < range.location + range.length; i++) {
    unichar currentChar = [attributedString.string characterAtIndex:i];
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

@end
