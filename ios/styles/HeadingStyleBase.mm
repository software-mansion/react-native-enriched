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

- (BOOL)needsZWS {
  return YES;
}

- (BOOL)appliesStylingToTyping {
  return YES;
}

- (void)applyStyling:(NSRange)range {
  [self.host.textView.textStorage
      enumerateAttribute:NSFontAttributeName
                 inRange:range
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
                [self.host.textView.textStorage addAttribute:NSFontAttributeName
                                                       value:newFont
                                                       range:subRange];
              }];
}

- (void)applyStylingToTypingAttrs:(NSMutableDictionary *)attributes {
  UIFont *currentFont = attributes[NSFontAttributeName];

  if (currentFont == nil) {
    currentFont = [self.host.config primaryFont];
  }

  UIFont *newFont = [currentFont setSize:[self getHeadingFontSize]];
  if ([self isHeadingBold]) {
    newFont = [newFont setBold];
  }

  attributes[NSFontAttributeName] = newFont;
}

// used to make sure headings dont persist after a newline is placed
- (BOOL)handleNewlinesInRange:(NSRange)range replacementText:(NSString *)text {
  // in a heading and a new text ends with a newline
  if ([self detect:self.host.textView.selectedRange] && text.length > 0 &&
      [[NSCharacterSet newlineCharacterSet]
          characterIsMember:[text characterAtIndex:text.length - 1]]) {
    // If the cursor sits directly before a ZWS, skip past it so the newline
    // is appended after the ZWS. This keeps the ZWS (and the heading) on the
    // current line while the new line the cursor lands on has no heading.
    // Without this the lone '\n' inherits heading attributes
    NSString *string = self.host.textView.textStorage.string;
    if (range.length == 0 && range.location < string.length &&
        [string characterAtIndex:range.location] == 0x200B) {
      range = NSMakeRange(range.location + 1, 0);
    }
    // do the replacement manually
    [TextInsertionUtils replaceText:text
                                 at:range
               additionalAttributes:nullptr
                               host:self.host
                      withSelection:YES];
    // remove the attributes at the new selection
    [self remove:self.host.textView.selectedRange withDirtyRange:YES];
    return YES;
  }
  return NO;
}

@end
