#import "EnrichedTextInputView.h"
#import "RangeUtils.h"
#import "StyleHeaders.h"
#import "TextInsertionUtils.h"

@implementation CheckboxListStyle

+ (StyleType)getType {
  return CheckboxList;
}

- (NSString *)getValue {
  return @"EnrichedCheckbox0";
}

- (BOOL)isParagraph {
  return YES;
}

- (BOOL)needsZWS {
  return YES;
}

- (void)applyStyling:(NSRange)range {
  CGFloat listHeadIndent = [self.input->config checkboxListMarginLeft] +
                           [self.input->config checkboxListGapWidth] +
                           [self.input->config checkboxListBoxSize];

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

- (BOOL)styleCondition:(id)value range:(NSRange)range {
  NSParagraphStyle *pStyle = (NSParagraphStyle *)value;
  return pStyle != nullptr && pStyle.textLists.count == 1 &&
         [pStyle.textLists.firstObject.markerFormat
             hasPrefix:@"EnrichedCheckbox"];
}

- (void)toggleWithChecked:(BOOL)checked range:(NSRange)range {
  NSRange actualRange = [self actualUsedRange:range];
  BOOL isPresent = [self detect:actualRange];

  if (isPresent) {
    [self remove:actualRange withDirtyRange:YES];
  } else {
    [self addWithChecked:checked
                   range:actualRange
              withTyping:YES
          withDirtyRange:YES];
  }
}

- (void)addWithChecked:(BOOL)checked
                 range:(NSRange)range
            withTyping:(BOOL)withTyping
        withDirtyRange:(BOOL)withDirtyRange {
  NSString *value = checked ? @"EnrichedCheckbox1" : @"EnrichedCheckbox0";
  [self add:range
           withValue:value
          withTyping:withTyping
      withDirtyRange:withDirtyRange];
}

// During dirty range re-application the default add: would use getValue
// (EnrichedCheckbox0) and lose the checked state. Instead, read the original
// marker format from the saved StylePair
- (void)reapplyFromStylePair:(StylePair *)pair {
  NSRange range = [pair.rangeValue rangeValue];
  NSParagraphStyle *savedPStyle = (NSParagraphStyle *)pair.styleValue;
  BOOL checked =
      savedPStyle != nullptr && [savedPStyle.textLists.firstObject.markerFormat
                                    isEqualToString:@"EnrichedCheckbox1"];
  [self addWithChecked:checked range:range withTyping:NO withDirtyRange:NO];
}

- (void)toggleCheckedAt:(NSUInteger)location {
  if (location >= self.input->textView.textStorage.length) {
    return;
  }

  NSParagraphStyle *pStyle =
      [self.input->textView.textStorage attribute:NSParagraphStyleAttributeName
                                          atIndex:location
                                   effectiveRange:NULL];
  NSTextList *list = pStyle.textLists.firstObject;

  BOOL isCurrentlyChecked =
      [list.markerFormat isEqualToString:@"EnrichedCheckbox1"];

  NSRange paragraphRange = [self.input->textView.textStorage.string
      paragraphRangeForRange:NSMakeRange(location, 0)];

  [self addWithChecked:!isCurrentlyChecked
                 range:paragraphRange
            withTyping:NO
        withDirtyRange:YES];
}

- (BOOL)getCheckboxStateAt:(NSUInteger)location {
  if (location >= self.input->textView.textStorage.length) {
    return NO;
  }

  NSParagraphStyle *style =
      [self.input->textView.textStorage attribute:NSParagraphStyleAttributeName
                                          atIndex:location
                                   effectiveRange:NULL];

  if (style && style.textLists.count > 0) {
    NSTextList *list = style.textLists.firstObject;
    if ([list.markerFormat isEqualToString:@"EnrichedCheckbox1"]) {
      return YES;
    }
  }

  return NO;
}

- (BOOL)handleNewlinesInRange:(NSRange)range replacementText:(NSString *)text {
  if ([self detect:self.input->textView.selectedRange] && text.length > 0 &&
      [[NSCharacterSet newlineCharacterSet]
          characterIsMember:[text characterAtIndex:text.length - 1]]) {
    // do the replacement manually
    [TextInsertionUtils replaceText:text
                                 at:range
               additionalAttributes:nullptr
                              input:self.input
                      withSelection:YES];
    // apply unchecked checkbox attributes to the new paragraph
    [self addWithChecked:NO
                   range:self.input->textView.selectedRange
              withTyping:YES
          withDirtyRange:YES];
    return YES;
  }
  return NO;
}

@end
