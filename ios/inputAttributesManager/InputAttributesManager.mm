#import "InputAttributesManager.h"
#import "AlignmentUtils.h"
#import "ArrayExtension.h"
#import "AttributeEntry.h"
#import "EnrichedTextInputView.h"
#import "ParagraphAttributesUtils.h"
#import "RangeUtils.h"
#import "StyleHeaders.h"
#import "StyleUtils.h"
#import "ZeroWidthSpaceUtils.h"

@implementation InputAttributesManager {
  NSMutableArray<NSValue *> *_dirtyRanges;
  NSSet *_customAttributesKeys;
  NSMutableSet *_removedTypingAttributes;
  BOOL _recentOnlySelectionStatus;
}

- (instancetype)initWithInput:(EnrichedTextInputView *)input {
  self = [super init];
  _input = input;
  _dirtyRanges = [[NSMutableArray alloc] init];
  _removedTypingAttributes = [[NSMutableSet alloc] init];
  _recentOnlySelectionStatus = NO;

  // setup customAttributes
  NSMutableSet *_customAttrsSet = [[NSMutableSet alloc] init];
  for (StyleBase *style in _input->stylesDict.allValues) {
    [_customAttrsSet addObject:[style getKey]];
  }
  _customAttributesKeys = _customAttrsSet;

  return self;
}
- (NSSet<NSString *> *)customAttributesKeys {
  return _customAttributesKeys;
}

- (void)addDirtyRange:(NSRange)range {
  [_dirtyRanges addObject:[NSValue valueWithRange:range]];
  _dirtyRanges = [[RangeUtils connectAndDedupeRanges:_dirtyRanges] mutableCopy];
}

- (NSArray *)getDirtyRanges {
  return _dirtyRanges;
}

- (void)shiftDirtyRangesWithEditedRange:(NSRange)editedRange
                         changeInLength:(NSInteger)delta {
  if (delta == 0) {
    return;
  }
  NSArray *shiftedRanges = [RangeUtils shiftRanges:_dirtyRanges
                                   withEditedRange:editedRange
                                    changeInLength:delta];
  _dirtyRanges =
      [[RangeUtils connectAndDedupeRanges:shiftedRanges] mutableCopy];
}

- (void)didRemoveTypingAttribute:(NSString *)key {
  [_removedTypingAttributes addObject:key];
}

- (void)clearRemovedTypingAttributes {
  [_removedTypingAttributes removeAllObjects];
}

- (void)handleDirtyRangesStyling {
  OrderedListStyle *orderedListStyle =
      (OrderedListStyle *)_input->stylesDict[@([OrderedListStyle getType])];

  for (NSValue *rangeObj in _dirtyRanges) {
    NSRange dirtyRange = [rangeObj rangeValue];

    // deletion (0-length dirtyRange) means we need to refresh the ordered
    // list margins. If the ordered list style is not present itself,
    // it might mean that we have just deleted a list element and need
    // to recalculate the potentially split list (current adjacent lists)
    if (dirtyRange.length == 0) {
      if (orderedListStyle != nil) {
        if ([orderedListStyle detect:dirtyRange]) {
          [orderedListStyle applyStyling:dirtyRange];
        } else {
          [orderedListStyle recalculateListsAroundEditedRange:dirtyRange];
        }
      }
      continue;
    }

    // dirty range can sometimes be wrong because of apple doing some changes
    // behind the scenes
    if (dirtyRange.location + dirtyRange.length >
        _input->textView.textStorage.string.length)
      continue;

    // firstly, get all styles' occurences in that dirty range
    NSMutableDictionary *presentStyles = [[NSMutableDictionary alloc] init];
    for (StyleBase *style in _input->stylesDict.allValues) {
      // the dict has keys of StyleType NSNumber and values of an array of all
      // occurences
      presentStyles[@([[style class] getType])] = [style all:dirtyRange];
    }

    // it's possible that ordered list style has just got removed,
    // so we have to refresh adjacent ordered lists
    if (orderedListStyle != nil &&
        [presentStyles[@([OrderedListStyle getType])] count] == 0) {
      [orderedListStyle recalculateListsAroundEditedRange:dirtyRange];
    }

    // now reset the attributes to default ones
    [_input->textView.textStorage setAttributes:_input->defaultTypingAttributes
                                          range:dirtyRange];

    // Restore ZWS layout metadata that is stored in regular attributes and was
    // overwritten by the default-attributes reset above.
    [ZeroWidthSpaceUtils applyKernForZeroWidthSpacesInRange:dirtyRange
                                                       host:_input];

    // Sort style types so paragraph styles come first. Their broad visual
    // attributes (e.g. foreground color, font) are laid down before inline
    // styles override them on their specific sub-ranges. Inline styles among
    // themselves follow their stylePriority.
    NSArray *sortedStyleTypes = [presentStyles.allKeys
        sortedArrayBySortKey:^NSInteger(NSNumber *styleType) {
          return [_input->stylesDict[styleType] stylePriority];
        }];

    // re-apply meta-attributes and apply visual styling following the saved
    // occurences.
    for (NSNumber *styleType in sortedStyleTypes) {
      StyleBase *style = _input->stylesDict[styleType];
      if (style == nullptr)
        continue;

      for (StylePair *stylePair in presentStyles[styleType]) {
        NSRange occurenceRange = [stylePair.rangeValue rangeValue];
        [style reapplyFromStylePair:stylePair];
        [style applyStyling:occurenceRange];
      }
    }
  }

  // do the typing attributes management, with no selection
  [self manageTypingAttributesWithOnlySelection:NO];

  [_dirtyRanges removeAllObjects];
}

- (void)restoreInlineStylesPresentInRange:(NSRange)range
                                intoAttrs:(NSMutableDictionary *)attrs {
  for (StyleBase *style in _input->stylesDict.allValues) {
    if ([style isParagraph])
      continue;
    if ([_removedTypingAttributes containsObject:[style getKey]])
      continue;

    AttributeEntry *entry = [style getEntryIfPresent:range];
    if (entry == nullptr)
      continue;

    attrs[entry.key] = entry.value;
  }
}

- (void)manageTypingAttributesWithOnlySelection:(BOOL)onlySelectionChanged {
  _recentOnlySelectionStatus = onlySelectionChanged;
  EnrichedInputTextView *textView = _input->textView;
  NSRange selectedRange = textView.selectedRange;

  // Typing attributes get reset (except alignment) when only selection changed
  // to an empty line (or empty line with newline).
  if (onlySelectionChanged) {
    // if there is no content, there is no need to clear the typing attributes
    if (textView.textStorage.string.length == 0) {
      return;
    }

    NSRange paragraphRange =
        [textView.textStorage.string paragraphRangeForRange:selectedRange];
    // User changed selection to an empty line (or empty line with a newline).
    if (paragraphRange.length == 0 ||
        (paragraphRange.length == 1 &&
         [[NSCharacterSet newlineCharacterSet]
             characterIsMember:[textView.textStorage.string
                                   characterAtIndex:paragraphRange
                                                        .location]])) {
      NSParagraphStyle *currentTypingStyle =
          textView.typingAttributes[NSParagraphStyleAttributeName];
      NSTextAlignment savedAlignment = currentTypingStyle
                                           ? currentTypingStyle.alignment
                                           : NSTextAlignmentNatural;

      [ParagraphAttributesUtils resetTypingAttributes:_input
                                  preservingAlignment:savedAlignment];

      // newlines could have been made within a valid inline style, so
      // we want to preserve typingAttributes so they are correctly
      // acknowledged when typing
      if (paragraphRange.length == 1) {
        NSMutableDictionary *newAttrs = [textView.typingAttributes mutableCopy];
        [self restoreInlineStylesPresentInRange:paragraphRange
                                      intoAttrs:newAttrs];
        textView.typingAttributes = newAttrs;
      }
      return;
    }
  }

  // General typing attributes management.

  // Firstly, we make sure only default + custom + paragraph typing attribtues
  // are left.
  NSMutableDictionary *newAttrs = [_input->defaultTypingAttributes mutableCopy];

  for (NSString *key in _input->textView.typingAttributes.allKeys) {
    if ([_customAttributesKeys containsObject:key]) {
      if ([key isEqualToString:NSParagraphStyleAttributeName]) {
        // NSParagraphStyle for paragraph styles -> only keep the textLists
        // property
        NSParagraphStyle *pStyle =
            (NSParagraphStyle *)_input->textView
                .typingAttributes[NSParagraphStyleAttributeName];
        if (pStyle != nullptr && pStyle.textLists.count >= 1) {
          NSMutableParagraphStyle *newPStyle =
              [[NSMutableParagraphStyle alloc] init];
          newPStyle.textLists = pStyle.textLists;
          newAttrs[NSParagraphStyleAttributeName] = newPStyle;
        }
      } else {
        // Inline styles -> keep the key/value as a whole
        newAttrs[key] = _input->textView.typingAttributes[key];
      }
    }
  }

  // Then, we add typingAttributes from present inline styles.
  // We check for the previous character to naturally extend typing attributes.
  // getEntryIfPresent properly returns nullptr for styles that we don't want to
  // extend this way. Attributes from _removedTypingAttributes aren't added
  // because they were just removed.
  if (selectedRange.location > 0) {
    [self restoreInlineStylesPresentInRange:NSMakeRange(
                                                selectedRange.location - 1, 1)
                                  intoAttrs:newAttrs];
  }

  // Apply active styles to typing attributes only for styles that require it so
  // the cursor correctly reflects the current formatting state (e.g. heading
  // size).
  for (StyleBase *style in _input->stylesDict.allValues) {
    if ([style appliesStylingToTyping] && [style detect:selectedRange]) {
      [style applyStylingToTypingAttrs:newAttrs];
    }
  }

  textView.typingAttributes = newAttrs;
}

- (void)repeatRecentTypingAttributesManagement {
  [self manageTypingAttributesWithOnlySelection:_recentOnlySelectionStatus];
}

@end
