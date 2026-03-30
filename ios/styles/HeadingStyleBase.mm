#import "EnrichedTextInputView.h"
#import "FontExtension.h"
#import "StyleHeaders.h"
#import "TextInsertionUtils.h"

@implementation HeadingStyleBase

// mock values since H1/2/3/4/5/6 style classes are used
+ (StyleType)getType {
  return None;
}

- (CGFloat)getHeadingFontSize {
  return 0;
}

- (BOOL)isHeadingBold {
  return NO;
}

- (BOOL)isParagraph {
  return YES;
}

- (void)applyStyling:(NSRange)range {
  NSRange fullRange =
      [self.input->textView.textStorage.string paragraphRangeForRange:range];

  [self.input->textView.textStorage
      enumerateAttribute:NSFontAttributeName
                 inRange:fullRange
                 options:0
              usingBlock:^(id _Nullable value, NSRange subRange,
                           BOOL *_Nonnull stop) {
                UIFont *font = (UIFont *)value;
                if (font == nullptr)
                  return;
                UIFont *newFont = [font setSize:[self getHeadingFontSize]];
                if ([self isHeadingBold]) {
                  newFont = [newFont setBold];
                }
                [self.input->textView.textStorage
                    addAttribute:NSFontAttributeName
                           value:newFont
                           range:subRange];
              }];
}

// used to make sure headings dont persist after a newline is placed
- (BOOL)handleNewlinesInRange:(NSRange)range replacementText:(NSString *)text {
  // in a heading and a new text ends with a newline
  if ([self detect:self.input->textView.selectedRange] && text.length > 0 &&
      [[NSCharacterSet newlineCharacterSet]
          characterIsMember:[text characterAtIndex:text.length - 1]]) {
    // do the replacement manually
    [TextInsertionUtils replaceText:text
                                 at:range
               additionalAttributes:nullptr
                              input:self.input
                      withSelection:YES];
    // remove the attributes at the new selection
    [self remove:self.input->textView.selectedRange withDirtyRange:YES];
    return YES;
  }
  return NO;
}

@end
