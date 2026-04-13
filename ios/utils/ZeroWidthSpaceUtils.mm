#import "ZeroWidthSpaceUtils.h"
#import "EnrichedTextInputView.h"
#import "StyleHeaders.h"
#import "TextInsertionUtils.h"
#import "UIView+React.h"

@implementation ZeroWidthSpaceUtils
+ (void)handleZeroWidthSpacesInInput:(id<EnrichedViewHost>)host {
  if (host == nullptr) {
    return;
  }

  [self removeSpacesIfNeededinInput:host];
  [self addSpacesIfNeededinInput:host];
}

+ (void)removeSpacesIfNeededinInput:(id<EnrichedViewHost>)host {
  NSMutableArray *indexesToBeRemoved = [[NSMutableArray alloc] init];
  NSRange preRemoveSelection = host.textView.selectedRange;

  for (int i = 0; i < host.textView.textStorage.string.length; i++) {
    unichar character = [host.textView.textStorage.string characterAtIndex:i];
    if (character == 0x200B) {
      NSRange characterRange = NSMakeRange(i, 1);

      NSRange paragraphRange = [host.textView.textStorage.string
          paragraphRangeForRange:characterRange];
      // having paragraph longer than 1 character means someone most likely
      // added something and we probably can remove the space
      BOOL removeSpace = paragraphRange.length > 1;
      // exception; 2 characters paragraph with zero width space + newline
      // here, we still need zero width space to keep the empty list items
      if (paragraphRange.length == 2 && paragraphRange.location == i &&
          [[NSCharacterSet newlineCharacterSet]
              characterIsMember:[host.textView.textStorage.string
                                    characterAtIndex:i + 1]]) {
        removeSpace = NO;
      }

      if (removeSpace) {
        [indexesToBeRemoved addObject:@(characterRange.location)];
        continue;
      }

      // zero width spaces with no needsZWS style on them get removed
      if (![self anyZWSStylePresentInRange:characterRange input:host]) {
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
                              input:host
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
  if ([host.textView isFirstResponder]) {
    host.textView.selectedRange =
        NSMakeRange(preRemoveSelection.location + postRemoveLocationOffset,
                    preRemoveSelection.length + postRemoveLengthOffset);
  }
}

// Collects active inline (non-paragraph) meta-attributes from the style
// dictionary so that ZWS characters carry the same meta-attributes that are
// currently active in the typing attributes. Only within the currently selected
// range!
+ (NSDictionary *)inlineMetaAttributesForInput:(id<EnrichedViewHost>)host {
  NSMutableDictionary *metaAttrs = [NSMutableDictionary new];
  for (NSNumber *type in host.stylesDict) {
    StyleBase *style = host.stylesDict[type];
    if (![style isParagraph]) {
      AttributeEntry *entry =
          [style getEntryIfPresent:host.textView.selectedRange];
      if (entry) {
        metaAttrs[entry.key] = entry.value;
      }
    }
  }
  return metaAttrs.count > 0 ? metaAttrs : nullptr;
}

+ (void)addSpacesIfNeededinInput:(id<EnrichedViewHost>)host {
  NSMutableArray *indexesToBeInserted = [[NSMutableArray alloc] init];
  NSRange preAddSelection = host.textView.selectedRange;

  for (NSUInteger i = 0; i < host.textView.textStorage.string.length; i++) {
    unichar character = [host.textView.textStorage.string characterAtIndex:i];

    if ([[NSCharacterSet newlineCharacterSet] characterIsMember:character]) {
      NSRange characterRange = NSMakeRange(i, 1);
      NSRange paragraphRange = [host.textView.textStorage.string
          paragraphRangeForRange:characterRange];

      if (paragraphRange.length == 1) {
        if ([self anyZWSStylePresentInRange:characterRange input:host]) {
          // we have an empty list or quote item with no space: add it!
          [indexesToBeInserted addObject:@(paragraphRange.location)];
        }
      }
    }
  }

  NSDictionary *metaAttrs = [self inlineMetaAttributesForInput:host];

  // do the replacing
  NSInteger offset = 0;
  NSInteger postAddLocationOffset = 0;
  NSInteger postAddLengthOffset = 0;
  for (NSNumber *index in indexesToBeInserted) {
    NSRange replaceRange = NSMakeRange([index integerValue] + offset, 1);
    [TextInsertionUtils replaceText:@"\u200B\n"
                                 at:replaceRange
               additionalAttributes:metaAttrs
                              input:host
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
  NSRange lastRange = NSMakeRange(host.textView.textStorage.string.length, 0);
  NSRange lastParagraphRange =
      [host.textView.textStorage.string paragraphRangeForRange:lastRange];
  if (lastParagraphRange.length == 0 &&
      [self anyZWSStylePresentInRange:lastRange input:host]) {
    [TextInsertionUtils insertText:@"\u200B"
                                at:lastRange.location
              additionalAttributes:metaAttrs
                             input:host
                     withSelection:NO];
  }

  // fix the selection if needed
  if ([host.textView isFirstResponder]) {
    host.textView.selectedRange =
        NSMakeRange(preAddSelection.location + postAddLocationOffset,
                    preAddSelection.length + postAddLengthOffset);
  }
}

+ (BOOL)handleBackspaceInRange:(NSRange)range
               replacementText:(NSString *)text
                         input:(id<EnrichedViewHost>)host {
  if (![text isEqualToString:@""]) {
    return NO;
  }
  if (host == nullptr) {
    return NO;
  }

  // Backspace at the very beginning of the input ({0, 0}).
  // Nothing to delete, but if the first paragraph has a needsZWS style,
  // remove it.
  if (range.length == 0 && range.location == 0) {
    NSRange firstParagraphRange = [host.textView.textStorage.string
        paragraphRangeForRange:NSMakeRange(0, 0)];
    if ([self removeZWSStyleInRange:firstParagraphRange input:host]) {
      return YES;
    }
    return NO;
  }

  if (range.length != 1) {
    return NO;
  }

  unichar character =
      [host.textView.textStorage.string characterAtIndex:range.location];
  // zero-width space got backspaced
  if (character == 0x200B) {
    // in such case: remove the whole line without the endline if there is one

    NSRange paragraphRange =
        [host.textView.textStorage.string paragraphRangeForRange:range];
    NSRange removalRange = paragraphRange;
    // if whole paragraph gets removed then 0 length for style removal
    NSRange styleRemovalRange = NSMakeRange(paragraphRange.location, 0);

    if ([[NSCharacterSet newlineCharacterSet]
            characterIsMember:[host.textView.textStorage.string
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
                              input:host
                      withSelection:YES];

    // and then remove associated styling
    [self removeZWSStyleInRange:styleRemovalRange input:host];

    return YES;
  }

  // Backspace at the start of a paragraph that has a ZWS-needing style.
  // The character being deleted is the newline at the end of the previous
  // paragraph. Instead of letting iOS merge the two lines, just remove the
  // style from the current paragraph.
  if ([[NSCharacterSet newlineCharacterSet] characterIsMember:character]) {
    NSUInteger nextParaStart = NSMaxRange(range);
    if (nextParaStart < host.textView.textStorage.string.length) {
      NSRange nextParagraphRange = [host.textView.textStorage.string
          paragraphRangeForRange:NSMakeRange(nextParaStart, 0)];
      if ([self removeZWSStyleInRange:nextParagraphRange input:host]) {
        return YES;
      }
    }
  }

  return NO;
}

+ (BOOL)anyZWSStylePresentInRange:(NSRange)range
                            input:(id<EnrichedViewHost>)host {
  for (NSNumber *type in host.stylesDict) {
    StyleBase *style = host.stylesDict[type];
    if ([style needsZWS] && [style detect:range]) {
      return YES;
    }
  }
  return NO;
}

+ (BOOL)removeZWSStyleInRange:(NSRange)range input:(id<EnrichedViewHost>)host {
  for (NSNumber *type in host.stylesDict) {
    StyleBase *style = host.stylesDict[type];
    if ([style needsZWS] && [style detect:range]) {
      [style remove:range withDirtyRange:YES];
      return YES;
    }
  }
  return NO;
}

@end
