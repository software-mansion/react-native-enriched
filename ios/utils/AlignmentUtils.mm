#import "AlignmentUtils.h"
#import "ParagraphsUtils.h"
#import "StyleHeaders.h"

@implementation AlignmentUtils

+ (void)applyAlignmentFromString:(NSString *)alignStr
                         toInput:(EnrichedTextInputView *)input {
  NSTextAlignment alignment = NSTextAlignmentNatural;

  if ([alignStr isEqualToString:@"left"]) {
    alignment = NSTextAlignmentLeft;
  } else if ([alignStr isEqualToString:@"center"]) {
    alignment = NSTextAlignmentCenter;
  } else if ([alignStr isEqualToString:@"right"]) {
    alignment = NSTextAlignmentRight;
  } else if ([alignStr isEqualToString:@"justify"]) {
    alignment = NSTextAlignmentJustified;
  }

  [AlignmentUtils setAlignment:alignment
                      forRange:input->textView.selectedRange
                       inInput:input];
}

+ (void)setAlignment:(NSTextAlignment)alignment
            forRange:(NSRange)forRange
             inInput:(EnrichedTextInputView *)input {
  UITextView *textView = input->textView;
  // Expand the range if we are inside a List
  NSRange targetRange = [AlignmentUtils expandRangeToContiguousList:forRange
                                                            inInput:input];
  NSArray *paragraphs =
      [ParagraphsUtils getSeparateParagraphsRangesIn:textView
                                               range:targetRange];

  [textView.textStorage beginEditing];
  for (NSValue *val in paragraphs) {
    NSRange pRange = [val rangeValue];
    [textView.textStorage
        enumerateAttribute:NSParagraphStyleAttributeName
                   inRange:pRange
                   options:0
                usingBlock:^(id value, NSRange range, BOOL *stop) {
                  NSMutableParagraphStyle *style =
                      value ? [value mutableCopy]
                            : [[NSParagraphStyle defaultParagraphStyle]
                                  mutableCopy];
                  style.alignment = alignment;

                  [textView.textStorage
                      addAttribute:NSParagraphStyleAttributeName
                             value:style
                             range:range];
                }];
  }
  [textView.textStorage endEditing];

  // Update Typing Attributes
  NSMutableDictionary *typingAttrs = [textView.typingAttributes mutableCopy];
  NSMutableParagraphStyle *typingStyle =
      [typingAttrs[NSParagraphStyleAttributeName] mutableCopy];
  typingStyle.alignment = alignment;
  typingAttrs[NSParagraphStyleAttributeName] = typingStyle;
  textView.typingAttributes = typingAttrs;

  [input anyTextMayHaveBeenModified];
}

+ (NSRange)expandRangeToContiguousList:(NSRange)range
                               inInput:(EnrichedTextInputView *)input {
  NSString *text = input->textView.textStorage.string;
  if (text.length == 0)
    return range;

  NSArray *listStyles = @[
    input->stylesDict[@([UnorderedListStyle getStyleType])],
    input->stylesDict[@([OrderedListStyle getStyleType])],
    input->stylesDict[@([CheckboxListStyle getStyleType])]
  ];

  NSRange expandedRange = range;

  // Expand Backward
  NSRange startParagraph =
      [text paragraphRangeForRange:NSMakeRange(range.location, 0)];

  // Find which list style is active at the start
  id<BaseStyleProtocol> activeStartStyle = nil;
  for (id<BaseStyleProtocol> style in listStyles) {
    if ([style detectStyle:startParagraph]) {
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

      if ([activeStartStyle detectStyle:prevPara]) {
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
  id<BaseStyleProtocol> activeEndStyle = nil;
  for (id<BaseStyleProtocol> style in listStyles) {
    if ([style detectStyle:endParagraph]) {
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

      if ([activeEndStyle detectStyle:nextPara]) {
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
