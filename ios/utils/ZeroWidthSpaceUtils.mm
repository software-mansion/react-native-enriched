#import "ZeroWidthSpaceUtils.h"
#import "EnrichedTextInputView.h"
#import "StyleHeaders.h"
#import "TextInsertionUtils.h"
#import "UIView+React.h"

@implementation ZeroWidthSpaceUtils
+ (void)handleZeroWidthSpacesInInput:(id)input {
  EnrichedTextInputView *typedInput = (EnrichedTextInputView *)input;
  if (typedInput == nullptr) {
    return;
  }

  [self removeSpacesIfNeededinInput:typedInput];
  [self addSpacesIfNeededinInput:typedInput];
}

+ (void)removeSpacesIfNeededinInput:(EnrichedTextInputView *)input {
  NSMutableArray *indexesToBeRemoved = [[NSMutableArray alloc] init];
  NSRange preRemoveSelection = input->textView.selectedRange;

  for (int i = 0; i < input->textView.textStorage.string.length; i++) {
    unichar character = [input->textView.textStorage.string characterAtIndex:i];
    if (character == 0x200B) {
      NSRange characterRange = NSMakeRange(i, 1);

      NSRange paragraphRange = [input->textView.textStorage.string
          paragraphRangeForRange:characterRange];
      // having paragraph longer than 1 character means someone most likely
      // added something and we probably can remove the space
      BOOL removeSpace = paragraphRange.length > 1;
      // exception; 2 characters paragraph with zero width space + newline
      // here, we still need zero width space to keep the empty list items
      if (paragraphRange.length == 2 && paragraphRange.location == i &&
          [[NSCharacterSet newlineCharacterSet]
              characterIsMember:[input->textView.textStorage.string
                                    characterAtIndex:i + 1]]) {
        removeSpace = NO;
      }

      if (removeSpace) {
        [indexesToBeRemoved addObject:@(characterRange.location)];
        continue;
      }

      // zero width spaces with no needsZWS style on them get removed
      if (![self anyZWSStylePresentInRange:characterRange input:input]) {
        [indexesToBeRemoved addObject:@(characterRange.location)];
      }
    }
  }

  // do the removing
  NSInteger offset = 0;
  NSInteger postRemoveLocationOffset = 0;
  NSInteger postRemoveLengthOffset = 0;
  for (NSNumber *index in indexesToBeRemoved) {
    NSRange replaceRange = NSMakeRange([index integerValue] + offset, 1);
    [TextInsertionUtils replaceText:@""
                                 at:replaceRange
               additionalAttributes:nullptr
                              input:input
                      withSelection:NO];
    offset -= 1;
    if ([index integerValue] < preRemoveSelection.location) {
      postRemoveLocationOffset -= 1;
    }
    if ([index integerValue] >= preRemoveSelection.location &&
        [index integerValue] < NSMaxRange(preRemoveSelection)) {
      postRemoveLengthOffset -= 1;
    }
  }

  // fix the selection if needed
  if ([input->textView isFirstResponder]) {
    input->textView.selectedRange =
        NSMakeRange(preRemoveSelection.location + postRemoveLocationOffset,
                    preRemoveSelection.length + postRemoveLengthOffset);
  }
}

// Collects active inline (non-paragraph) meta-attributes from the style
// dictionary so that ZWS characters carry the same meta-attributes that are
// currently active in the typing attributes. Only within the currently selected
// range!
+ (NSDictionary *)inlineMetaAttributesForInput:(EnrichedTextInputView *)input {
  NSMutableDictionary *metaAttrs = [NSMutableDictionary new];
  for (NSNumber *type in input->stylesDict) {
    StyleBase *style = input->stylesDict[type];
    if (![style isParagraph]) {
      AttributeEntry *entry =
          [style getEntryIfPresent:input->textView.selectedRange];
      if (entry) {
        metaAttrs[entry.key] = entry.value;
      }
    }
  }
  return metaAttrs.count > 0 ? metaAttrs : nullptr;
}

+ (void)addSpacesIfNeededinInput:(EnrichedTextInputView *)input {
  NSMutableArray *indexesToBeInserted = [[NSMutableArray alloc] init];
  NSRange preAddSelection = input->textView.selectedRange;

  for (NSUInteger i = 0; i < input->textView.textStorage.string.length; i++) {
    unichar character = [input->textView.textStorage.string characterAtIndex:i];

    if ([[NSCharacterSet newlineCharacterSet] characterIsMember:character]) {
      NSRange characterRange = NSMakeRange(i, 1);
      NSRange paragraphRange = [input->textView.textStorage.string
          paragraphRangeForRange:characterRange];

      if (paragraphRange.length == 1) {
        if ([self anyZWSStylePresentInRange:characterRange input:input]) {
          // we have an empty list or quote item with no space: add it!
          [indexesToBeInserted addObject:@(paragraphRange.location)];
        }
      }
    }
  }

  NSDictionary *metaAttrs = [self inlineMetaAttributesForInput:input];

  // do the replacing
  NSInteger offset = 0;
  NSInteger postAddLocationOffset = 0;
  NSInteger postAddLengthOffset = 0;
  for (NSNumber *index in indexesToBeInserted) {
    NSRange replaceRange = NSMakeRange([index integerValue] + offset, 1);
    [TextInsertionUtils replaceText:@"\u200B\n"
                                 at:replaceRange
               additionalAttributes:metaAttrs
                              input:input
                      withSelection:NO];
    offset += 1;
    if ([index integerValue] < preAddSelection.location) {
      postAddLocationOffset += 1;
    }
    if ([index integerValue] >= preAddSelection.location &&
        [index integerValue] < NSMaxRange(preAddSelection)) {
      postAddLengthOffset += 1;
    }
  }

  // additional check for last index of the input
  NSRange lastRange = NSMakeRange(input->textView.textStorage.string.length, 0);
  NSRange lastParagraphRange =
      [input->textView.textStorage.string paragraphRangeForRange:lastRange];
  if (lastParagraphRange.length == 0) {
    if ([self anyZWSStylePresentInRange:lastRange input:input]) {
      [TextInsertionUtils insertText:@"\u200B"
                                  at:lastRange.location
                additionalAttributes:metaAttrs
                               input:input
                       withSelection:NO];
    }
  }

  // fix the selection if needed
  if ([input->textView isFirstResponder]) {
    input->textView.selectedRange =
        NSMakeRange(preAddSelection.location + postAddLocationOffset,
                    preAddSelection.length + postAddLengthOffset);
  }
}

+ (BOOL)handleBackspaceInRange:(NSRange)range
               replacementText:(NSString *)text
                         input:(id)input {
  if (![text isEqualToString:@""]) {
    return NO;
  }
  EnrichedTextInputView *typedInput = (EnrichedTextInputView *)input;
  if (typedInput == nullptr) {
    return NO;
  }

  // Backspace at the very beginning of the input ({0, 0}).
  // Nothing to delete, but if the first paragraph has a needsZWS style,
  // remove it.
  if (range.length == 0 && range.location == 0) {
    NSRange firstParagraphRange = [typedInput->textView.textStorage.string
        paragraphRangeForRange:NSMakeRange(0, 0)];
    if ([self removeZWSStyleInRange:firstParagraphRange input:typedInput]) {
      return YES;
    }
    return NO;
  }

  if (range.length != 1) {
    return NO;
  }

  unichar character =
      [typedInput->textView.textStorage.string characterAtIndex:range.location];
  // zero-width space got backspaced
  if (character == 0x200B) {
    // in such case: remove the whole line without the endline if there is one

    NSRange paragraphRange =
        [typedInput->textView.textStorage.string paragraphRangeForRange:range];
    NSRange removalRange = paragraphRange;
    // if whole paragraph gets removed then 0 length for style removal
    NSRange styleRemovalRange = NSMakeRange(paragraphRange.location, 0);

    if ([[NSCharacterSet newlineCharacterSet]
            characterIsMember:[typedInput->textView.textStorage.string
                                  characterAtIndex:NSMaxRange(paragraphRange) -
                                                   1]]) {
      // if endline is there, don't remove it
      removalRange =
          NSMakeRange(paragraphRange.location, paragraphRange.length - 1);
      // if endline is left then 1 length for style removal
      styleRemovalRange = NSMakeRange(paragraphRange.location, 1);
    }

    // remove the ZWS (keep the newline if present)
    [TextInsertionUtils replaceText:@""
                                 at:removalRange
               additionalAttributes:nullptr
                              input:typedInput
                      withSelection:YES];

    // and then remove associated styling
    [self removeZWSStyleInRange:styleRemovalRange input:typedInput];

    return YES;
  }

  // Backspace at the start of a paragraph that has a ZWS-needing style.
  // The character being deleted is the newline at the end of the previous
  // paragraph. Instead of letting iOS merge the two lines, just remove the
  // style from the current paragraph.
  if ([[NSCharacterSet newlineCharacterSet] characterIsMember:character]) {
    NSUInteger nextParaStart = NSMaxRange(range);
    if (nextParaStart < typedInput->textView.textStorage.string.length) {
      NSRange nextParagraphRange = [typedInput->textView.textStorage.string
          paragraphRangeForRange:NSMakeRange(nextParaStart, 0)];
      if ([self removeZWSStyleInRange:nextParagraphRange input:typedInput]) {
        return YES;
      }
    }
  }

  return NO;
}

+ (BOOL)anyZWSStylePresentInRange:(NSRange)range
                            input:(EnrichedTextInputView *)input {
  for (NSNumber *type in input->stylesDict) {
    StyleBase *style = input->stylesDict[type];
    if ([style needsZWS] && [style detect:range]) {
      return YES;
    }
  }
  return NO;
}

+ (BOOL)removeZWSStyleInRange:(NSRange)range
                        input:(EnrichedTextInputView *)input {
  for (NSNumber *type in input->stylesDict) {
    StyleBase *style = input->stylesDict[type];
    if ([style needsZWS] && [style detect:range]) {
      [style remove:range withDirtyRange:YES];
      return YES;
    }
  }
  return NO;
}

@end
