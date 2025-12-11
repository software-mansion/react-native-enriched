#import "EnrichedTextInputView.h"
#import "FontExtension.h"
#import "OccurenceUtils.h"
#import "ParagraphsUtils.h"
#import "StyleHeaders.h"
#import "TextInsertionUtils.h"

@implementation UnorderedListStyle {
  EnrichedTextInputView *_input;
}

+ (StyleType)getStyleType {
  return UnorderedList;
}

+ (BOOL)isParagraphStyle {
  return YES;
}

- (CGFloat)getHeadIndent {
  // lists are drawn manually
  // margin before bullet + gap between bullet and paragraph
  return [_input->config unorderedListMarginLeft] +
         [_input->config unorderedListGapWidth];
}

- (instancetype)initWithInput:(id)input {
  self = [super init];
  _input = (EnrichedTextInputView *)input;
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

// we assume correct paragraph range is already given
- (void)addAttributes:(NSRange)range withTypingAttr:(BOOL)withTypingAttr {
  NSTextList *bullet =
      [[NSTextList alloc] initWithMarkerFormat:NSTextListMarkerDisc options:0];
  NSArray *paragraphs =
      [ParagraphsUtils getSeparateParagraphsRangesIn:_input->textView
                                               range:range];
  // if we fill empty lines with zero width spaces, we need to offset later
  // ranges
  NSInteger offset = 0;
  // needed for range adjustments
  NSRange preModificationRange = _input->textView.selectedRange;

  // let's not emit some weird selection changes or text/html changes
  _input->blockEmitting = YES;

  for (NSValue *value in paragraphs) {
    // take previous offsets into consideration
    NSRange fixedRange = NSMakeRange([value rangeValue].location + offset,
                                     [value rangeValue].length);

    // length 0 with first line, length 1 and newline with some empty lines in
    // the middle
    if (fixedRange.length == 0 ||
        (fixedRange.length == 1 &&
         [[NSCharacterSet newlineCharacterSet]
             characterIsMember:[_input->textView.textStorage.string
                                   characterAtIndex:fixedRange.location]])) {
      [TextInsertionUtils insertText:@"\u200B"
                                  at:fixedRange.location
                additionalAttributes:nullptr
                               input:_input
                       withSelection:NO];
      fixedRange = NSMakeRange(fixedRange.location, fixedRange.length + 1);
      offset += 1;
    }

    [_input->textView.textStorage
        enumerateAttribute:NSParagraphStyleAttributeName
                   inRange:fixedRange
                   options:0
                usingBlock:^(id _Nullable value, NSRange range,
                             BOOL *_Nonnull stop) {
                  NSMutableParagraphStyle *pStyle =
                      [(NSParagraphStyle *)value mutableCopy];
                  pStyle.textLists = @[ bullet ];
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
    pStyle.textLists = @[ bullet ];
    pStyle.headIndent = [self getHeadIndent];
    pStyle.firstLineHeadIndent = [self getHeadIndent];
    typingAttrs[NSParagraphStyleAttributeName] = pStyle;
    _input->textView.typingAttributes = typingAttrs;
  }
}

// does pretty much the same as normal addAttributes, just need to get the range
- (void)addTypingAttributes {
  [self addAttributes:_input->textView.selectedRange withTypingAttr:YES];
}

- (void)removeAttributes:(NSRange)range {
  NSArray *paragraphs =
      [ParagraphsUtils getSeparateParagraphsRangesIn:_input->textView
                                               range:range];

  [_input->textView.textStorage beginEditing];

  for (NSValue *value in paragraphs) {
    NSRange range = [value rangeValue];
    [_input->textView.textStorage
        enumerateAttribute:NSParagraphStyleAttributeName
                   inRange:range
                   options:0
                usingBlock:^(id _Nullable value, NSRange range,
                             BOOL *_Nonnull stop) {
                  NSMutableParagraphStyle *pStyle =
                      [(NSParagraphStyle *)value mutableCopy];
                  pStyle.textLists = @[];
                  pStyle.headIndent = 0;
                  pStyle.firstLineHeadIndent = 0;
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
      // a backspace on the very first input's line list point
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

- (BOOL)tryHandlingListShorcutInRange:(NSRange)range
                      replacementText:(NSString *)text {
  NSRange paragraphRange =
      [_input->textView.textStorage.string paragraphRangeForRange:range];
  // space was added - check if we are both at the paragraph beginning + 1
  // character (which we want to be a dash)
  if ([text isEqualToString:@" "] &&
      range.location - 1 == paragraphRange.location) {
    unichar charBefore = [_input->textView.textStorage.string
        characterAtIndex:range.location - 1];
    if (charBefore == '-') {
      // we got a match - add a list if possible
      if ([_input handleStyleBlocksAndConflicts:[[self class] getStyleType]
                                          range:paragraphRange]) {
        // don't emit during the replacing
        _input->blockEmitting = YES;

        // remove the dash
        [TextInsertionUtils replaceText:@""
                                     at:NSMakeRange(paragraphRange.location, 1)
                   additionalAttributes:nullptr
                                  input:_input
                          withSelection:YES];

        _input->blockEmitting = NO;

        // add attributes on the dashless paragraph
        [self addAttributes:NSMakeRange(paragraphRange.location,
                                        paragraphRange.length - 1)
             withTypingAttr:YES];
        return YES;
      }
    }
  }
  return NO;
}

- (BOOL)styleCondition:(id _Nullable)value:(NSRange)range {
  NSParagraphStyle *paragraph = (NSParagraphStyle *)value;
  return paragraph != nullptr && paragraph.textLists.count == 1 &&
         paragraph.textLists.firstObject.markerFormat == NSTextListMarkerDisc;
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

@end
