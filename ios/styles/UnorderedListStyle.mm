#import "EnrichedTextInputView.h"
#import "RangeUtils.h"
#import "StyleHeaders.h"
#import "TextInsertionUtils.h"

@implementation UnorderedListStyle

+ (StyleType)getType {
  return UnorderedList;
}

- (NSString *)getValue {
  return @"UnorderedList";
}

- (BOOL)isParagraph {
  return YES;
}

- (void)applyStyling:(NSRange)range {
  // lists are drawn manually
  // margin before bullet + gap between bullet and paragraph
  CGFloat listHeadIndent = [self.input->config unorderedListMarginLeft] +
                           [self.input->config unorderedListGapWidth];

  [self.input->textView.textStorage
      enumerateAttribute:NSParagraphStyleAttributeName
                 inRange:range
                 options:0
              usingBlock:^(id _Nullable value, NSRange range,
                           BOOL *_Nonnull stop) {
                NSMutableParagraphStyle *pStyle =
                    [(NSParagraphStyle *)value mutableCopy];
                pStyle.headIndent = listHeadIndent;
                pStyle.firstLineHeadIndent = listHeadIndent;
                [self.input->textView.textStorage
                    addAttribute:NSParagraphStyleAttributeName
                           value:pStyle
                           range:range];
              }];
}

//- (BOOL)handleBackspaceInRange:(NSRange)range replacementText:(NSString *)text
//{
//  if ([self detectStyle:_input->textView.selectedRange] && text.length == 0) {
//    // backspace while the style is active
//
//    NSRange paragraphRange = [_input->textView.textStorage.string
//        paragraphRangeForRange:_input->textView.selectedRange];
//
//    if (NSEqualRanges(_input->textView.selectedRange, NSMakeRange(0, 0))) {
//      // a backspace on the very first input's line list point
//      // it doesn't run textVieDidChange so we need to manually remove
//      // attributes
//      [self removeAttributes:paragraphRange];
//      return YES;
//    } else if (range.location == paragraphRange.location - 1) {
//      // same case in other lines; here, the removed range location will be
//      // exactly 1 less than paragraph range location
//      [self removeAttributes:paragraphRange];
//      return YES;
//    }
//  }
//  return NO;
//}
//
//- (BOOL)tryHandlingListShorcutInRange:(NSRange)range
//                      replacementText:(NSString *)text {
//  NSRange paragraphRange =
//      [_input->textView.textStorage.string paragraphRangeForRange:range];
//  // space was added - check if we are both at the paragraph beginning + 1
//  // character (which we want to be a dash)
//  if ([text isEqualToString:@" "] &&
//      range.location - 1 == paragraphRange.location) {
//    unichar charBefore = [_input->textView.textStorage.string
//        characterAtIndex:range.location - 1];
//    if (charBefore == '-') {
//      // we got a match - add a list if possible
//      if ([_input handleStyleBlocksAndConflicts:[[self class] getStyleType]
//                                          range:paragraphRange]) {
//        // don't emit during the replacing
//        _input->blockEmitting = YES;
//
//        // remove the dash
//        [TextInsertionUtils replaceText:@""
//                                     at:NSMakeRange(paragraphRange.location,
//                                     1)
//                   additionalAttributes:nullptr
//                                  input:_input
//                          withSelection:YES];
//
//        _input->blockEmitting = NO;
//
//        // add attributes on the dashless paragraph
//        [self addAttributes:NSMakeRange(paragraphRange.location,
//                                        paragraphRange.length - 1)
//             withTypingAttr:YES];
//        return YES;
//      }
//    }
//  }
//  return NO;
//}

@end
