#import "AlignmentUtils.h"
#import "RangeUtils.h"
#import "StyleHeaders.h"

@implementation AlignmentUtils

+ (void)applyAlignments:(NSArray<AlignmentEntry *> *)alignments
                 offset:(NSInteger)offset
                toInput:(EnrichedTextInputView *)input {
  for (AlignmentEntry *entry in alignments) {
    // Offset the range (e.g. if inserting into the middle of text)
    NSRange finalRange =
        NSMakeRange(offset + entry.range.location, entry.range.length);

    [AlignmentUtils setAlignment:entry.alignment
                        forRange:finalRange
                         inInput:input
                  withTypingAttr:NO];
  }
}

+ (void)applyAlignmentFromString:(NSString *)alignStr
                         toInput:(EnrichedTextInputView *)input {
  NSTextAlignment alignment = [AlignmentUtils stringToAlignment:alignStr];

  [AlignmentUtils setAlignment:alignment
                      forRange:input->textView.selectedRange
                       inInput:input
                withTypingAttr:YES];
}

+ (void)setAlignment:(NSTextAlignment)alignment
            forRange:(NSRange)forRange
             inInput:(EnrichedTextInputView *)input
      withTypingAttr:(BOOL)withTypingAttr {
  // Expand the range if we are inside a List
  NSRange targetRange = [AlignmentUtils expandRangeToContiguousList:forRange
                                                            inInput:input];
  AlignmentStyle *alignmentStyle =
      (AlignmentStyle *)input->stylesDict[@([AlignmentStyle getType])];
  if (alignmentStyle == nullptr) {
    return;
  }

  [alignmentStyle setAlignment:alignment
                         range:targetRange
                    withTyping:withTypingAttr
                withDirtyRange:YES];

  [input anyTextMayHaveBeenModified];
}

+ (NSString *)alignmentToString:(NSTextAlignment)alignment {
  switch (alignment) {
  case NSTextAlignmentLeft:
    return @"left";
  case NSTextAlignmentCenter:
    return @"center";
  case NSTextAlignmentRight:
    return @"right";
  case NSTextAlignmentJustified:
    return @"justify";
  case NSTextAlignmentNatural:
  default:
    return @"left";
  }
}

+ (NSTextAlignment)stringToAlignment:(NSString *)alignmentString {
  NSString *normalized = [alignmentString lowercaseString];

  if ([normalized isEqualToString:@"left"]) {
    return NSTextAlignmentLeft;
  }
  if ([normalized isEqualToString:@"center"]) {
    return NSTextAlignmentCenter;
  }
  if ([normalized isEqualToString:@"right"]) {
    return NSTextAlignmentRight;
  }
  if ([normalized isEqualToString:@"justify"]) {
    return NSTextAlignmentJustified;
  }

  return NSTextAlignmentNatural;
}

+ (NSString *)currentAlignmentStringForInput:(EnrichedTextInputView *)input {
  UITextView *textView = input->textView;
  NSParagraphStyle *paraStyle = nil;

  if (textView.textStorage.length > 0) {
    NSUInteger location =
        MIN(textView.selectedRange.location, textView.textStorage.length - 1);
    paraStyle = [textView.textStorage attribute:NSParagraphStyleAttributeName
                                        atIndex:location
                                 effectiveRange:nil];
  }

  if (paraStyle == nil) {
    paraStyle = textView.typingAttributes[NSParagraphStyleAttributeName];
  }

  NSTextAlignment alignment =
      paraStyle ? paraStyle.alignment : NSTextAlignmentNatural;
  return [AlignmentUtils alignmentToString:alignment];
}

+ (NSRange)expandRangeToContiguousList:(NSRange)range
                               inInput:(EnrichedTextInputView *)input {
  NSString *text = input->textView.textStorage.string;
  if (text.length == 0)
    return range;

  NSArray<StyleBase *> *listStyles = @[
    input->stylesDict[@([UnorderedListStyle getType])],
    input->stylesDict[@([OrderedListStyle getType])],
    input->stylesDict[@([CheckboxListStyle getType])]
  ];

  NSRange expandedRange = range;

  // Expand Backward
  NSRange startParagraph =
      [text paragraphRangeForRange:NSMakeRange(range.location, 0)];

  // Find which list style is active at the start
  StyleBase *activeStartStyle = nil;
  for (StyleBase *style in listStyles) {
    if ([style detect:startParagraph]) {
      activeStartStyle = style;
      break;
    }
  }

  // If we found a list style, walk backwards until it stops
  if (activeStartStyle) {
    NSRange currentPara = startParagraph;
    while (currentPara.location > 0) {
      // Check the paragraph before the current one
      NSRange prevPara = [text
          paragraphRangeForRange:NSMakeRange(currentPara.location - 1, 0)];

      if ([activeStartStyle detect:prevPara]) {
        // It's still the same list -> Expand our range.
        expandedRange = NSUnionRange(expandedRange, prevPara);
        currentPara = prevPara;
      } else {
        // The list ended here.
        break;
      }
    }
  }

  // Expand forward, we check the paragraph at the end of the current selection
  NSUInteger endLoc =
      (range.length > 0) ? (NSMaxRange(range) - 1) : range.location;
  NSRange endParagraph = [text paragraphRangeForRange:NSMakeRange(endLoc, 0)];

  // Find which list style is active at the end
  StyleBase *activeEndStyle = nil;
  for (StyleBase *style in listStyles) {
    if ([style detect:endParagraph]) {
      activeEndStyle = style;
      break;
    }
  }

  // If we found a list style, walk forwards until it stops
  if (activeEndStyle) {
    NSRange currentPara = endParagraph;
    while (NSMaxRange(currentPara) < text.length) {
      // Check the paragraph after the current one
      NSRange nextPara =
          [text paragraphRangeForRange:NSMakeRange(NSMaxRange(currentPara), 0)];

      if ([activeEndStyle detect:nextPara]) {
        // It's still the same list -> expand our range.
        expandedRange = NSUnionRange(expandedRange, nextPara);
        currentPara = nextPara;
      } else {
        break;
      }
    }
  }

  return expandedRange;
}

@end
