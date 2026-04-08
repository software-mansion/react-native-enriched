#import "EnrichedTextInputView.h"
#import "RangeUtils.h"
#import "StyleHeaders.h"
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
  // margin before marker + gap between marker and paragraph
  CGFloat listHeadIndent = [self.host.config orderedListMarginLeft] +
                           [self.host.config orderedListGapWidth];

  [self.host.textView.textStorage
      enumerateAttribute:NSParagraphStyleAttributeName
                 inRange:range
                 options:0
              usingBlock:^(id _Nullable value, NSRange range,
                           BOOL *_Nonnull stop) {
                NSMutableParagraphStyle *pStyle =
                    [(NSParagraphStyle *)value mutableCopy];
                pStyle.headIndent = listHeadIndent;
                pStyle.firstLineHeadIndent = listHeadIndent;
                [self.host.textView.textStorage
                    addAttribute:NSParagraphStyleAttributeName
                           value:pStyle
                           range:range];
              }];
}

- (BOOL)tryHandlingListShorcutInRange:(NSRange)range
                      replacementText:(NSString *)text {
  NSRange paragraphRange =
      [self.host.textView.textStorage.string paragraphRangeForRange:range];
  // a dot was added - check if we are both at the paragraph beginning + 1
  // character (which we want to be a digit '1')
  if ([text isEqualToString:@"."] &&
      range.location - 1 == paragraphRange.location) {
    unichar charBefore = [self.host.textView.textStorage.string
        characterAtIndex:range.location - 1];
    if (charBefore == '1') {
      // we got a match - add a list if possible
      if ([self.host handleStyleBlocksAndConflicts:[[self class] getType]
                                             range:paragraphRange]) {
        // don't emit during the replacing
        self.host.blockEmitting = YES;

        // remove the number
        [TextInsertionUtils replaceText:@""
                                     at:NSMakeRange(paragraphRange.location, 1)
                   additionalAttributes:nullptr
                                  input:self.host
                          withSelection:YES];

        self.host.blockEmitting = NO;

        // add attributes on the paragraph
        [self add:NSMakeRange(paragraphRange.location,
                              paragraphRange.length - 1)
                withTyping:YES
            withDirtyRange:YES];

        return YES;
      }
    }
  }
  return NO;
}

@end
