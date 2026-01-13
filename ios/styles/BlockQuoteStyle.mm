#import "ColorExtension.h"
#import "EnrichedTextInputView.h"
#import "OccurenceUtils.h"
#import "ParagraphsUtils.h"
#import "StyleHeaders.h"
#import "TextInsertionUtils.h"

@implementation BlockQuoteStyle {
  EnrichedTextInputView *_input;
  NSArray *_stylesToExclude;
}

+ (StyleType)getStyleType {
  return BlockQuote;
}

+ (BOOL)isParagraphStyle {
  return YES;
}

+ (const char *)tagName {
  return "blockquote";
}

+ (const char *)subTagName {
  return "p";
}

+ (BOOL)isSelfClosing {
  return NO;
}

+ (NSAttributedStringKey)attributeKey {
  return NSParagraphStyleAttributeName;
}

- (instancetype)initWithInput:(id)input {
  self = [super init];
  _input = (EnrichedTextInputView *)input;
  _stylesToExclude = @[ @(InlineCode), @(Mention), @(Link) ];
  return self;
}

- (CGFloat)getHeadIndent {
  // rectangle width + gap
  return [_input->config blockquoteBorderWidth] +
         [_input->config blockquoteGapWidth];
}

// the range will already be the full paragraph/s range
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
                  pStyle.headIndent = [self getHeadIndent];
                  pStyle.firstLineHeadIndent = [self getHeadIndent];
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
    pStyle.headIndent = [self getHeadIndent];
    pStyle.firstLineHeadIndent = [self getHeadIndent];
    typingAttrs[NSParagraphStyleAttributeName] = pStyle;
    _input->textView.typingAttributes = typingAttrs;
  }
}

// does pretty much the same as addAttributes
- (void)addTypingAttributes {
  [self addAttributes:_input->textView.selectedRange withTypingAttr:YES];
}

- (void)removeAttributes:(NSRange)range {
  NSArray *paragraphs =
      [ParagraphsUtils getSeparateParagraphsRangesIn:_input->textView
                                               range:range];

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
                  pStyle.headIndent = 0;
                  pStyle.firstLineHeadIndent = 0;
                  [_input->textView.textStorage
                      addAttribute:NSParagraphStyleAttributeName
                             value:pStyle
                             range:range];
                }];
  }

  // also remove typing attributes
  NSMutableDictionary *typingAttrs =
      [_input->textView.typingAttributes mutableCopy];
  NSMutableParagraphStyle *pStyle =
      [typingAttrs[NSParagraphStyleAttributeName] mutableCopy];
  pStyle.headIndent = 0;
  pStyle.firstLineHeadIndent = 0;
  typingAttrs[NSParagraphStyleAttributeName] = pStyle;
  _input->textView.typingAttributes = typingAttrs;
}

// needed for the sake of style conflicts, needs to do exactly the same as
// removeAttribtues
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
    } else if (range.location == paragraphRange.location - 1) {
      // same case in other lines; here, the removed range location will be
      // exactly 1 less than paragraph range location
      [self removeAttributes:paragraphRange];
      return YES;
    }
  }
  return NO;
}

- (BOOL)styleCondition:(id _Nullable)value range:(NSRange)range {
  NSParagraphStyle *pStyle = (NSParagraphStyle *)value;
  return pStyle != nullptr && pStyle.headIndent == [self getHeadIndent] &&
         pStyle.firstLineHeadIndent == [self getHeadIndent] &&
         pStyle.textLists.count == 0;
}

- (BOOL)detectStyle:(NSRange)range {
  if (range.length >= 1) {
    return [OccurenceUtils detect:NSParagraphStyleAttributeName
                        withInput:_input
                          inRange:range
                    withCondition:^BOOL(id _Nullable value, NSRange range) {
                      return [self styleCondition:value range:range];
                    }];
  } else {
    return [OccurenceUtils detect:NSParagraphStyleAttributeName
                        withInput:_input
                          atIndex:range.location
                    checkPrevious:YES
                    withCondition:^BOOL(id _Nullable value, NSRange range) {
                      return [self styleCondition:value range:range];
                    }];
  }
}

- (BOOL)anyOccurence:(NSRange)range {
  return [OccurenceUtils any:NSParagraphStyleAttributeName
                   withInput:_input
                     inRange:range
               withCondition:^BOOL(id _Nullable value, NSRange range) {
                 return [self styleCondition:value range:range];
               }];
}

- (NSArray<StylePair *> *_Nullable)findAllOccurences:(NSRange)range {
  return [OccurenceUtils all:NSParagraphStyleAttributeName
                   withInput:_input
                     inRange:range
               withCondition:^BOOL(id _Nullable value, NSRange range) {
                 return [self styleCondition:value range:range];
               }];
}

// general checkup correcting blockquote color
// since links, mentions and inline code affects coloring, the checkup gets done
// only outside of them
- (void)manageBlockquoteColor {
  if ([[_input->config blockquoteColor]
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
          enumerateAttribute:NSForegroundColorAttributeName
                     inRange:currRange
                     options:0
                  usingBlock:^(id _Nullable value, NSRange range,
                               BOOL *_Nonnull stop) {
                    UIColor *newColor = nullptr;
                    BOOL colorApplied = [(UIColor *)value
                        isEqualToColor:[_input->config blockquoteColor]];

                    if (colorApplied && !selfDetected) {
                      newColor = [_input->config primaryColor];
                    } else if (!colorApplied && selfDetected) {
                      newColor = [_input->config blockquoteColor];
                    }

                    if (newColor != nullptr) {
                      [_input->textView.textStorage
                          addAttribute:NSForegroundColorAttributeName
                                 value:newColor
                                 range:currRange];
                      [_input->textView.textStorage
                          addAttribute:NSUnderlineColorAttributeName
                                 value:newColor
                                 range:currRange];
                      [_input->textView.textStorage
                          addAttribute:NSStrikethroughColorAttributeName
                                 value:newColor
                                 range:currRange];
                    }
                  }];
    }
  }
}

@end
