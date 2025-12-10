#import "ColorExtension.h"
#import "EnrichedTextInputView.h"
#import "FontExtension.h"
#import "OccurenceUtils.h"
#import "ParagraphsUtils.h"
#import "StyleHeaders.h"
#import "TextInsertionUtils.h"

@implementation CodeBlockStyle {
  EnrichedTextInputView *_input;
  NSArray *_stylesToExclude;
}

+ (StyleType)getStyleType {
  return CodeBlock;
}

+ (BOOL)isParagraphStyle {
  return YES;
}

- (instancetype)initWithInput:(id)input {
  self = [super init];
  _input = (EnrichedTextInputView *)input;
  _stylesToExclude = @[ @(InlineCode), @(Mention), @(Link) ];
  return self;
}

- (void)applyStyle:(NSRange)range {
  BOOL isStylePresent = [self detectStyle:range];
  if (range.length >= 1) {
    isStylePresent ? [self removeAttributes:range]
                   : [self addAttributes:range withTypingAttr:YES];
  } else {
    isStylePresent ? [self removeTypingAttributes] : [self addTypingAttributes];
  }
}

- (void)addAttributes:(NSRange)range withTypingAttr:(BOOL)withTypingAttr {
  NSTextList *codeBlockList =
      [[NSTextList alloc] initWithMarkerFormat:@"codeblock" options:0];
  NSArray *paragraphs =
      [ParagraphsUtils getSeparateParagraphsRangesIn:_input->textView
                                               range:range];
  // if we fill empty lines with zero width spaces, we need to offset later
  // ranges
  NSInteger offset = 0;
  NSRange preModificationRange = _input->textView.selectedRange;

  // to not emit any space filling selection/text changes
  _input->blockEmitting = YES;

  for (NSValue *value in paragraphs) {
    NSRange pRange = NSMakeRange([value rangeValue].location + offset,
                                 [value rangeValue].length);
    // length 0 with first line, length 1 and newline with some empty lines in
    // the middle
    if (pRange.length == 0 ||
        (pRange.length == 1 &&
         [[NSCharacterSet newlineCharacterSet]
             characterIsMember:[_input->textView.textStorage.string
                                   characterAtIndex:pRange.location]])) {
      [TextInsertionUtils insertText:@"\u200B"
                                  at:pRange.location
                additionalAttributes:nullptr
                               input:_input
                       withSelection:NO];
      pRange = NSMakeRange(pRange.location, pRange.length + 1);
      offset += 1;
    }

    [_input->textView.textStorage
        enumerateAttribute:NSParagraphStyleAttributeName
                   inRange:pRange
                   options:0
                usingBlock:^(id _Nullable value, NSRange range,
                             BOOL *_Nonnull stop) {
                  NSMutableParagraphStyle *pStyle =
                      [(NSParagraphStyle *)value mutableCopy];
                  pStyle.textLists = @[ codeBlockList ];
                  [_input->textView.textStorage
                      addAttribute:NSParagraphStyleAttributeName
                             value:pStyle
                             range:range];
                }];
  }

  // back to emitting
  _input->blockEmitting = NO;

  if (preModificationRange.length == 0) {
    // fix selection if only one line was possibly made a list and filled with a
    // space
    _input->textView.selectedRange = preModificationRange;
  } else {
    // in other cases, fix the selection with newly made offsets
    _input->textView.selectedRange = NSMakeRange(
        preModificationRange.location, preModificationRange.length + offset);
  }

  // also add typing attributes
  if (withTypingAttr) {
    NSMutableDictionary *typingAttrs =
        [_input->textView.typingAttributes mutableCopy];
    NSMutableParagraphStyle *pStyle =
        [typingAttrs[NSParagraphStyleAttributeName] mutableCopy];
    pStyle.textLists = @[ codeBlockList ];
    typingAttrs[NSParagraphStyleAttributeName] = pStyle;

    _input->textView.typingAttributes = typingAttrs;
  }
}

- (void)addTypingAttributes {
  [self addAttributes:_input->textView.selectedRange withTypingAttr:YES];
}

- (void)removeAttributes:(NSRange)range {
  NSArray *paragraphs =
      [ParagraphsUtils getSeparateParagraphsRangesIn:_input->textView
                                               range:range];

  [_input->textView.textStorage beginEditing];

  for (NSValue *value in paragraphs) {
    NSRange pRange = [value rangeValue];

    [_input->textView.textStorage
        enumerateAttribute:NSParagraphStyleAttributeName
                   inRange:pRange
                   options:0
                usingBlock:^(id _Nullable value, NSRange range,
                             BOOL *_Nonnull stop) {
                  NSMutableParagraphStyle *pStyle =
                      [(NSParagraphStyle *)value mutableCopy];
                  pStyle.textLists = @[];
                  [_input->textView.textStorage
                      addAttribute:NSParagraphStyleAttributeName
                             value:pStyle
                             range:range];
                }];
  }

  [_input->textView.textStorage endEditing];

  // also remove typing attributes
  NSMutableDictionary *typingAttrs =
      [_input->textView.typingAttributes mutableCopy];
  NSMutableParagraphStyle *pStyle =
      [typingAttrs[NSParagraphStyleAttributeName] mutableCopy];
  pStyle.textLists = @[];

  typingAttrs[NSParagraphStyleAttributeName] = pStyle;

  _input->textView.typingAttributes = typingAttrs;
}

- (void)removeTypingAttributes {
  [self removeAttributes:_input->textView.selectedRange];
}

- (BOOL)handleBackspaceInRange:(NSRange)range replacementText:(NSString *)text {
  if ([self detectStyle:_input->textView.selectedRange] && text.length == 0) {
    // backspace while the style is active

    NSRange paragraphRange = [_input->textView.textStorage.string
        paragraphRangeForRange:_input->textView.selectedRange];

    if (NSEqualRanges(_input->textView.selectedRange, NSMakeRange(0, 0))) {
      // a backspace on the very first input's line quote
      // it doesn't run textVieDidChange so we need to manually remove
      // attributes
      [self removeAttributes:paragraphRange];
      return YES;
    }
  }
  return NO;
}

- (BOOL)styleCondition:(id _Nullable)value:(NSRange)range {
  NSParagraphStyle *paragraph = (NSParagraphStyle *)value;
  return paragraph != nullptr && paragraph.textLists.count == 1 &&
         [paragraph.textLists.firstObject.markerFormat
             isEqualToString:@"codeblock"];
}

- (BOOL)detectStyle:(NSRange)range {
  if (range.length >= 1) {
    return [OccurenceUtils detect:NSParagraphStyleAttributeName
                        withInput:_input
                          inRange:range
                    withCondition:^BOOL(id _Nullable value, NSRange range) {
                      return [self styleCondition:value:range];
                    }];
  } else {
    return [OccurenceUtils detect:NSParagraphStyleAttributeName
                        withInput:_input
                          atIndex:range.location
                    checkPrevious:YES
                    withCondition:^BOOL(id _Nullable value, NSRange range) {
                      return [self styleCondition:value:range];
                    }];
  }
}

- (BOOL)anyOccurence:(NSRange)range {
  return [OccurenceUtils any:NSParagraphStyleAttributeName
                   withInput:_input
                     inRange:range
               withCondition:^BOOL(id _Nullable value, NSRange range) {
                 return [self styleCondition:value:range];
               }];
}

- (NSArray<StylePair *> *_Nullable)findAllOccurences:(NSRange)range {
  return [OccurenceUtils all:NSParagraphStyleAttributeName
                   withInput:_input
                     inRange:range
               withCondition:^BOOL(id _Nullable value, NSRange range) {
                 return [self styleCondition:value:range];
               }];
}

- (void)manageCodeBlockFontAndColor {
  if ([[_input->config codeBlockFgColor]
          isEqualToColor:[_input->config primaryColor]]) {
    return;
  }

  NSRange wholeRange =
      NSMakeRange(0, _input->textView.textStorage.string.length);
  NSArray *paragraphs =
      [ParagraphsUtils getSeparateParagraphsRangesIn:_input->textView
                                               range:wholeRange];

  for (NSValue *pValue in paragraphs) {
    NSRange paragraphRange = [pValue rangeValue];
    NSArray *properRanges = [OccurenceUtils getRangesWithout:_stylesToExclude
                                                   withInput:_input
                                                     inRange:paragraphRange];

    for (NSValue *value in properRanges) {
      NSRange currRange = [value rangeValue];
      BOOL selfDetected = [self detectStyle:currRange];

      [_input->textView.textStorage
          enumerateAttribute:NSFontAttributeName
                     inRange:currRange
                     options:0
                  usingBlock:^(id _Nullable value, NSRange range,
                               BOOL *_Nonnull stop) {
                    UIFont *currentFont = (UIFont *)value;
                    UIFont *newFont = nullptr;

                    BOOL isCodeFont = [[currentFont familyName]
                        isEqualToString:[[_input->config monospacedFont]
                                            familyName]];

                    if (isCodeFont && !selfDetected) {
                      newFont = [[[_input->config primaryFont]
                          withFontTraits:currentFont]
                          setSize:currentFont.pointSize];
                    } else if (!isCodeFont && selfDetected) {
                      newFont = [[[_input->config monospacedFont]
                          withFontTraits:currentFont]
                          setSize:currentFont.pointSize];
                    }

                    if (newFont != nullptr) {
                      [_input->textView.textStorage
                          addAttribute:NSFontAttributeName
                                 value:newFont
                                 range:range];
                    }
                  }];

      [_input->textView.textStorage
          enumerateAttribute:NSForegroundColorAttributeName
                     inRange:currRange
                     options:0
                  usingBlock:^(id _Nullable value, NSRange range,
                               BOOL *_Nonnull stop) {
                    UIColor *newColor = nullptr;
                    BOOL colorApplied = [(UIColor *)value
                        isEqualToColor:[_input->config codeBlockFgColor]];

                    if (colorApplied && !selfDetected) {
                      newColor = [_input->config primaryColor];
                    } else if (!colorApplied && selfDetected) {
                      newColor = [_input->config codeBlockFgColor];
                    }

                    if (newColor != nullptr) {
                      [_input->textView.textStorage
                          addAttribute:NSForegroundColorAttributeName
                                 value:newColor
                                 range:range];
                    }
                  }];
    }
  }
}

@end
