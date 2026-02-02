#import "AttributesManager.h"
#import "AttributeEntry.h"
#import "EnrichedTextInputView.h"
#import "RangeUtils.h"
#import "StyleHeaders.h"

@implementation AttributesManager {
  NSMutableArray<NSValue *> *_dirtyRanges;
  NSSet *_customAttributesKeys;
  NSMutableSet *_removedTypingAttributes;
}

- (instancetype)initWithInput:(EnrichedTextInputView *)input {
  self = [super init];
  _input = input;
  _dirtyRanges = [[NSMutableArray alloc] init];
  _removedTypingAttributes = [[NSMutableSet alloc] init];

  // setup customAttributes
  NSMutableSet *_customAttrsSet = [[NSMutableSet alloc] init];
  for (StyleBase *style in _input->stylesDict.allValues) {
    [_customAttrsSet addObject:[style getKey]];
  }
  _customAttributesKeys = _customAttrsSet;

  return self;
}

- (void)addDirtyRange:(NSRange)range {
  if (range.length == 0) {
    return;
  }
  [_dirtyRanges addObject:[NSValue valueWithRange:range]];
  _dirtyRanges = [[RangeUtils connectAndDedupeRanges:_dirtyRanges] mutableCopy];
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

- (void)handleDirtyRangesStyling {
  for (NSValue *rangeObj in _dirtyRanges) {
    NSRange dirtyRange = [rangeObj rangeValue];

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

    // now reset the attributes to default ones
    [_input->textView.textStorage setAttributes:_input->defaultTypingAttributes
                                          range:dirtyRange];

    // then apply styling and re-apply meta-attribtues following the saved
    // occurences
    for (NSNumber *styleType in presentStyles) {
      StyleBase *style = _input->stylesDict[styleType];
      if (style == nullptr)
        continue;

      for (StylePair *stylePair in presentStyles[styleType]) {
        NSRange occurenceRange = [stylePair.rangeValue rangeValue];
        [style applyStyling:occurenceRange];
        [style add:occurenceRange withTyping:NO];
      }
    }
  }
  // do the typing attributes management, with no selection
  [self manageTypingAttributesWithOnlySelection:NO];

  [_dirtyRanges removeAllObjects];
}

- (void)manageTypingAttributesWithOnlySelection:(BOOL)onlySelectionChanged {
  InputTextView *textView = _input->textView;
  NSRange selectedRange = textView.selectedRange;

  // Typing attributes get reset when only selection changed to an empty line
  // (or empty line with newline).
  if (onlySelectionChanged) {
    NSRange paragraphRange =
        [textView.textStorage.string paragraphRangeForRange:selectedRange];
    // User changed selection to an empty line (or empty line with a newline).
    if (paragraphRange.length == 0 ||
        (paragraphRange.length == 1 &&
         [[NSCharacterSet newlineCharacterSet]
             characterIsMember:[textView.textStorage.string
                                   characterAtIndex:paragraphRange
                                                        .location]])) {
      textView.typingAttributes = _input->defaultTypingAttributes;
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
        if (pStyle != nullptr && pStyle.textLists.count == 1) {
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
  for (StyleBase *style in _input->stylesDict.allValues) {
    if ([style isParagraph])
      continue;
    if ([_removedTypingAttributes containsObject:[style getKey]])
      continue;

    AttributeEntry *entry = nullptr;

    if (![style isParagraph] && selectedRange.location > 0) {
      entry =
          [style getEntryIfPresent:NSMakeRange(selectedRange.location - 1, 1)];
    } else if ([style isParagraph]) {
      NSRange paragraphRange = [_input->textView.textStorage.string
          paragraphRangeForRange:selectedRange];
      entry = [style getEntryIfPresent:paragraphRange];
    }

    if (entry == nullptr)
      continue;

    newAttrs[entry.key] = entry.value;
  }

  [_removedTypingAttributes removeAllObjects];
  textView.typingAttributes = newAttrs;
}

@end
