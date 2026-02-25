#import "EnrichedTextInputView.h"
#import "FontExtension.h"
#import "OccurenceUtils.h"
#import "ParagraphsUtils.h"
#import "StyleHeaders.h"
#import "TextInsertionUtils.h"

@implementation HeadingStyleBase

// mock values since H1/2/3/4/5/6Style classes anyway are used
+ (StyleType)getStyleType {
  return None;
}
- (CGFloat)getHeadingFontSize {
  return 0;
}
- (NSString *)getHeadingLevelString {
  return @"";
}
- (BOOL)isHeadingBold {
  return false;
}
+ (BOOL)isParagraphStyle {
  return true;
}

- (EnrichedTextInputView *)typedInput {
  return (EnrichedTextInputView *)input;
}

- (instancetype)initWithInput:(id)input {
  self = [super init];
  self->input = input;
  return self;
}

// the range will already be the full paragraph/s range
// but if the paragraph is empty it still is of length 0
- (void)applyStyle:(NSRange)range {
  BOOL isStylePresent = [self detectStyle:range];
  if (range.length >= 1) {
    isStylePresent ? [self removeAttributes:range]
                   : [self addAttributes:range withTypingAttr:YES];
  } else {
    isStylePresent ? [self removeTypingAttributes] : [self addTypingAttributes];
  }
}

- (NSTextList *)getTextListObject {
  return [[NSTextList alloc]
      initWithMarkerFormat:[NSString
                               stringWithFormat:@"{heading:%@}",
                                                [self getHeadingLevelString]]
                   options:0];
}

// the range will already be the proper full paragraph/s range
- (void)addAttributes:(NSRange)range withTypingAttr:(BOOL)withTypingAttr {
  NSTextList *textListMarker = [self getTextListObject];
  NSArray *paragraphs =
      [ParagraphsUtils getSeparateParagraphsRangesIn:[self typedInput]->textView
                                               range:range];
  for (NSValue *value in paragraphs) {
    NSRange paragraphRange = [value rangeValue];

    [[self typedInput]->textView.textStorage
        enumerateAttribute:NSParagraphStyleAttributeName
                   inRange:paragraphRange
                   options:0
                usingBlock:^(id _Nullable value, NSRange range,
                             BOOL *_Nonnull stop) {
                  NSMutableParagraphStyle *pStyle =
                      [(NSParagraphStyle *)value mutableCopy];
                  pStyle.textLists = @[ textListMarker ];
                  [[self typedInput]->textView.textStorage
                      addAttribute:NSParagraphStyleAttributeName
                             value:pStyle
                             range:range];
                }];

    [[self typedInput]->textView.textStorage
        enumerateAttribute:NSFontAttributeName
                   inRange:paragraphRange
                   options:0
                usingBlock:^(id _Nullable value, NSRange range,
                             BOOL *_Nonnull stop) {
                  UIFont *font = (UIFont *)value;
                  if (font == nullptr) {
                    return;
                  }
                  UIFont *newFont = [font setSize:[self getHeadingFontSize]];
                  if ([self isHeadingBold]) {
                    newFont = [newFont setBold];
                  }
                  [[self typedInput]->textView.textStorage
                      addAttribute:NSFontAttributeName
                             value:newFont
                             range:range];
                }];
  }

  // also toggle typing attributes
  if (withTypingAttr) {
    [self addTypingAttributes];
  }
}

// will always be called on empty paragraphs so only typing attributes can be
// changed
- (void)addTypingAttributes {
  NSMutableDictionary *newTypingAttrs =
      [[self typedInput]->textView.typingAttributes mutableCopy];

  NSMutableParagraphStyle *pStyle =
      [newTypingAttrs[NSParagraphStyleAttributeName] mutableCopy];
  if (pStyle != nullptr) {
    pStyle.textLists = @[ [self getTextListObject] ];
    newTypingAttrs[NSParagraphStyleAttributeName] = pStyle;
  }

  UIFont *currentFontAttr = (UIFont *)newTypingAttrs[NSFontAttributeName];
  if (currentFontAttr != nullptr) {
    UIFont *newFont = [currentFontAttr setSize:[self getHeadingFontSize]];
    if ([self isHeadingBold]) {
      newFont = [newFont setBold];
    }
    newTypingAttrs[NSFontAttributeName] = newFont;
  }

  [self typedInput]->textView.typingAttributes = newTypingAttrs;
}

// we need to remove the style from the whole paragraph
- (void)removeAttributes:(NSRange)range {
  NSArray *paragraphs =
      [ParagraphsUtils getSeparateParagraphsRangesIn:[self typedInput]->textView
                                               range:range];

  for (NSValue *value in paragraphs) {
    NSRange paragraphRange = [value rangeValue];
    [[self typedInput]->textView.textStorage
        enumerateAttribute:NSParagraphStyleAttributeName
                   inRange:paragraphRange
                   options:0
                usingBlock:^(id _Nullable value, NSRange range,
                             BOOL *_Nonnull stop) {
                  NSMutableParagraphStyle *pStyle =
                      [(NSParagraphStyle *)value mutableCopy];
                  pStyle.textLists = @[];
                  [[self typedInput]->textView.textStorage
                      addAttribute:NSParagraphStyleAttributeName
                             value:pStyle
                             range:range];
                }];

    [[self typedInput]->textView.textStorage
        enumerateAttribute:NSFontAttributeName
                   inRange:paragraphRange
                   options:0
                usingBlock:^(id _Nullable value, NSRange range,
                             BOOL *_Nonnull stop) {
                  UIFont *newFont = [(UIFont *)value
                      setSize:[[[self typedInput]->config scaledPrimaryFontSize]
                                  floatValue]];
                  if ([self isHeadingBold]) {
                    newFont = [newFont removeBold];
                  }
                  [[self typedInput]->textView.textStorage
                      addAttribute:NSFontAttributeName
                             value:newFont
                             range:range];
                }];
  }

  // typing attributes still need to be removed
  NSMutableDictionary *newTypingAttrs =
      [[self typedInput]->textView.typingAttributes mutableCopy];

  NSMutableParagraphStyle *pStyle =
      [newTypingAttrs[NSParagraphStyleAttributeName] mutableCopy];
  if (pStyle != nullptr) {
    pStyle.textLists = @[];
    newTypingAttrs[NSParagraphStyleAttributeName] = pStyle;
  }

  UIFont *currentFontAttr = (UIFont *)newTypingAttrs[NSFontAttributeName];
  if (currentFontAttr != nullptr) {
    UIFont *newFont = [currentFontAttr
        setSize:[[[self typedInput]->config scaledPrimaryFontSize] floatValue]];
    if ([self isHeadingBold]) {
      newFont = [newFont removeBold];
    }
    newTypingAttrs[NSFontAttributeName] = newFont;
  }

  [self typedInput]->textView.typingAttributes = newTypingAttrs;
}

- (void)removeTypingAttributes {
  // All the heading still needs to be removed because this function may be
  // called in conflicting styles logic. Typing attributes already get removed
  // in there as well.
  [self removeAttributes:[self typedInput]->textView.selectedRange];
}

- (BOOL)styleCondition:(id _Nullable)value range:(NSRange)range {
  NSParagraphStyle *paragraph = (NSParagraphStyle *)value;
  return paragraph != nullptr && paragraph.textLists.count == 1 &&
         [paragraph.textLists.firstObject.markerFormat
             isEqualToString:[self getTextListObject].markerFormat];
}

- (BOOL)detectStyle:(NSRange)range {
  if (range.length >= 1) {
    return [OccurenceUtils detect:NSParagraphStyleAttributeName
                        withInput:[self typedInput]
                          inRange:range
                    withCondition:^BOOL(id _Nullable value, NSRange range) {
                      return [self styleCondition:value range:range];
                    }];
  } else {
    return [OccurenceUtils detect:NSParagraphStyleAttributeName
                        withInput:[self typedInput]
                          atIndex:range.location
                    checkPrevious:YES
                    withCondition:^BOOL(id _Nullable value, NSRange range) {
                      return [self styleCondition:value range:range];
                    }];
  }
}

- (BOOL)anyOccurence:(NSRange)range {
  return [OccurenceUtils any:NSParagraphStyleAttributeName
                   withInput:[self typedInput]
                     inRange:range
               withCondition:^BOOL(id _Nullable value, NSRange range) {
                 return [self styleCondition:value range:range];
               }];
}

- (NSArray<StylePair *> *_Nullable)findAllOccurences:(NSRange)range {
  return [OccurenceUtils all:NSParagraphStyleAttributeName
                   withInput:[self typedInput]
                     inRange:range
               withCondition:^BOOL(id _Nullable value, NSRange range) {
                 return [self styleCondition:value range:range];
               }];
}

// used to make sure headings dont persist after a newline is placed
- (BOOL)handleNewlinesInRange:(NSRange)range replacementText:(NSString *)text {
  // in a heading and a new text ends with a newline
  if ([self detectStyle:[self typedInput]->textView.selectedRange] &&
      text.length > 0 &&
      [[NSCharacterSet newlineCharacterSet]
          characterIsMember:[text characterAtIndex:text.length - 1]]) {
    // do the replacement manually
    [TextInsertionUtils replaceText:text
                                 at:range
               additionalAttributes:nullptr
                              input:[self typedInput]
                      withSelection:YES];
    // remove the attributes at the new selection
    [self removeAttributes:[self typedInput]->textView.selectedRange];
    return YES;
  }
  return NO;
}

// Backspacing a line after a heading "into" a heading will not result in the
// text not receiving heading font attributes.
// Hence, we fix these attributes then.
- (BOOL)handleBackspaceInRange:(NSRange)range replacementText:(NSString *)text {
  // Must be a backspace.
  if (text.length != 0) {
    return NO;
  }

  // Backspace must have removed a newline character.
  NSString *removedString =
      [[self typedInput]->textView.textStorage.string substringWithRange:range];
  if ([removedString
          rangeOfCharacterFromSet:[NSCharacterSet newlineCharacterSet]]
          .location == NSNotFound) {
    return NO;
  }

  // Heading style must have been present in a paragraph before the backspaced
  // range.
  NSRange paragraphBeforeBackspaceRange =
      [[self typedInput]->textView.textStorage.string
          paragraphRangeForRange:NSMakeRange(range.location, 0)];
  if (![self detectStyle:paragraphBeforeBackspaceRange]) {
    return NO;
  }

  // Manually do the replacing.
  [TextInsertionUtils replaceText:text
                               at:range
             additionalAttributes:nullptr
                            input:[self typedInput]
                    withSelection:YES];
  // Reapply attributes at the beginning of the backspaced range (it will cover
  // the whole paragraph properly).
  [self addAttributes:NSMakeRange(range.location, 0) withTypingAttr:YES];

  return YES;
}

@end
