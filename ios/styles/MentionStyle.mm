#import "ColorExtension.h"
#import "EnrichedTextInputView.h"
#import "OccurenceUtils.h"
#import "StyleHeaders.h"
#import "TextInsertionUtils.h"
#import "UIView+React.h"
#import "WordsUtils.h"

// custom NSAttributedStringKey to differentiate from links
static NSString *const MentionAttributeName = @"MentionAttributeName";

@implementation MentionStyle {
  EnrichedTextInputView *_input;
  NSValue *_activeMentionRange;
  NSString *_activeMentionIndicator;
  BOOL _blockMentionEditing;
}

+ (StyleType)getStyleType {
  return Mention;
}

+ (BOOL)isParagraphStyle {
  return NO;
}

- (instancetype)initWithInput:(id)input {
  self = [super init];
  _input = (EnrichedTextInputView *)input;
  _activeMentionRange = nullptr;
  _activeMentionIndicator = nullptr;
  _blockMentionEditing = NO;
  return self;
}

- (void)applyStyle:(NSRange)range {
  // no-op for mentions
}

- (void)addAttributes:(NSRange)range withTypingAttr:(BOOL)withTypingAttr {
  // no-op for mentions
}

- (void)addTypingAttributes {
  // no-op for mentions
}

// we have to make sure all mentions get removed properly
- (void)removeAttributes:(NSRange)range {
  BOOL someMentionHadUnderline = NO;

  NSArray<StylePair *> *mentions = [self findAllOccurences:range];
  [_input->textView.textStorage beginEditing];
  for (StylePair *pair in mentions) {
    NSRange mentionRange =
        [self getFullMentionRangeAt:[pair.rangeValue rangeValue].location];
    [_input->textView.textStorage removeAttribute:MentionAttributeName
                                            range:mentionRange];
    [_input->textView.textStorage addAttribute:NSForegroundColorAttributeName
                                         value:[_input->config primaryColor]
                                         range:mentionRange];
    [_input->textView.textStorage addAttribute:NSUnderlineColorAttributeName
                                         value:[_input->config primaryColor]
                                         range:mentionRange];
    [_input->textView.textStorage addAttribute:NSStrikethroughColorAttributeName
                                         value:[_input->config primaryColor]
                                         range:mentionRange];
    [_input->textView.textStorage removeAttribute:NSBackgroundColorAttributeName
                                            range:mentionRange];

    if ([self stylePropsWithParams:pair.styleValue].decorationLine ==
        DecorationUnderline) {
      [_input->textView.textStorage
          removeAttribute:NSUnderlineStyleAttributeName
                    range:mentionRange];
      someMentionHadUnderline = YES;
    }
  }
  [_input->textView.textStorage endEditing];

  // remove typing attributes as well
  NSMutableDictionary *newTypingAttrs =
      [_input->textView.typingAttributes mutableCopy];
  newTypingAttrs[NSForegroundColorAttributeName] =
      [_input->config primaryColor];
  newTypingAttrs[NSUnderlineColorAttributeName] = [_input->config primaryColor];
  newTypingAttrs[NSStrikethroughColorAttributeName] =
      [_input->config primaryColor];
  [newTypingAttrs removeObjectForKey:NSBackgroundColorAttributeName];
  if (someMentionHadUnderline) {
    [newTypingAttrs removeObjectForKey:NSUnderlineStyleAttributeName];
  }
  _input->textView.typingAttributes = newTypingAttrs;
}

// used for conflicts, we have to remove the whole mention
- (void)removeTypingAttributes {
  NSRange mentionRange =
      [self getFullMentionRangeAt:_input->textView.selectedRange.location];
  [_input->textView.textStorage beginEditing];
  [_input->textView.textStorage removeAttribute:MentionAttributeName
                                          range:mentionRange];
  [_input->textView.textStorage addAttribute:NSForegroundColorAttributeName
                                       value:[_input->config primaryColor]
                                       range:mentionRange];
  [_input->textView.textStorage addAttribute:NSUnderlineColorAttributeName
                                       value:[_input->config primaryColor]
                                       range:mentionRange];
  [_input->textView.textStorage addAttribute:NSStrikethroughColorAttributeName
                                       value:[_input->config primaryColor]
                                       range:mentionRange];
  [_input->textView.textStorage removeAttribute:NSBackgroundColorAttributeName
                                          range:mentionRange];

  MentionParams *params = [self getMentionParamsAt:mentionRange.location];
  if ([self stylePropsWithParams:params].decorationLine ==
      DecorationUnderline) {
    [_input->textView.textStorage removeAttribute:NSUnderlineStyleAttributeName
                                            range:mentionRange];
  }
  [_input->textView.textStorage endEditing];

  // remove typing attributes as well
  NSMutableDictionary *newTypingAttrs =
      [_input->textView.typingAttributes mutableCopy];
  newTypingAttrs[NSForegroundColorAttributeName] =
      [_input->config primaryColor];
  newTypingAttrs[NSUnderlineColorAttributeName] = [_input->config primaryColor];
  newTypingAttrs[NSStrikethroughColorAttributeName] =
      [_input->config primaryColor];
  [newTypingAttrs removeObjectForKey:NSBackgroundColorAttributeName];
  if ([self stylePropsWithParams:params].decorationLine ==
      DecorationUnderline) {
    [newTypingAttrs removeObjectForKey:NSUnderlineStyleAttributeName];
  }
  _input->textView.typingAttributes = newTypingAttrs;
}

- (BOOL)styleCondition:(id _Nullable)value:(NSRange)range {
  MentionParams *params = (MentionParams *)value;
  return params != nullptr;
}

- (BOOL)detectStyle:(NSRange)range {
  if (range.length >= 1) {
    return [OccurenceUtils detect:MentionAttributeName
                        withInput:_input
                          inRange:range
                    withCondition:^BOOL(id _Nullable value, NSRange range) {
                      return [self styleCondition:value:range];
                    }];
  } else {
    return [self getMentionParamsAt:range.location] != nullptr;
  }
}

- (BOOL)anyOccurence:(NSRange)range {
  return [OccurenceUtils any:MentionAttributeName
                   withInput:_input
                     inRange:range
               withCondition:^BOOL(id _Nullable value, NSRange range) {
                 return [self styleCondition:value:range];
               }];
}

- (NSArray<StylePair *> *_Nullable)findAllOccurences:(NSRange)range {
  return [OccurenceUtils all:MentionAttributeName
                   withInput:_input
                     inRange:range
               withCondition:^BOOL(id _Nullable value, NSRange range) {
                 return [self styleCondition:value:range];
               }];
}

// MARK: - Public non-standard methods

- (void)addMention:(NSString *)indicator
              text:(NSString *)text
        attributes:(NSString *)attributes {
  if (_activeMentionRange == nullptr) {
    return;
  }

  // we block callbacks resulting from manageMentionEditing while we tamper with
  // them here
  _blockMentionEditing = YES;

  MentionParams *params = [[MentionParams alloc] init];
  params.text = text;
  params.indicator = indicator;
  params.attributes = attributes;

  MentionStyleProps *styleProps =
      [_input->config mentionStylePropsForIndicator:indicator];

  NSMutableDictionary *newAttrs = [@{
    MentionAttributeName : params,
    NSForegroundColorAttributeName : styleProps.color,
    NSUnderlineColorAttributeName : styleProps.color,
    NSStrikethroughColorAttributeName : styleProps.color,
    NSBackgroundColorAttributeName :
        [styleProps.backgroundColor colorWithAlphaIfNotTransparent:0.4],
  } mutableCopy];

  if (styleProps.decorationLine == DecorationUnderline) {
    newAttrs[NSUnderlineStyleAttributeName] = @(NSUnderlineStyleSingle);
  }

  // add a single space after the mention
  NSString *newText = [NSString stringWithFormat:@"%@ ", text];
  NSRange rangeToBeReplaced = [_activeMentionRange rangeValue];
  [TextInsertionUtils replaceText:newText
                               at:rangeToBeReplaced
             additionalAttributes:nullptr
                            input:_input
                    withSelection:YES];

  // THEN, add the attributes to not apply them on the space
  [_input->textView.textStorage
      addAttributes:newAttrs
              range:NSMakeRange(rangeToBeReplaced.location, text.length)];

  // mention editing should finish
  [self removeActiveMentionRange];

  // unlock editing
  _blockMentionEditing = NO;
}

- (void)addMentionAtRange:(NSRange)range params:(MentionParams *)params {
  _blockMentionEditing = YES;

  MentionStyleProps *styleProps =
      [_input->config mentionStylePropsForIndicator:params.indicator];

  NSMutableDictionary *newAttrs = [@{
    MentionAttributeName : params,
    NSForegroundColorAttributeName : styleProps.color,
    NSUnderlineColorAttributeName : styleProps.color,
    NSStrikethroughColorAttributeName : styleProps.color,
    NSBackgroundColorAttributeName :
        [styleProps.backgroundColor colorWithAlphaIfNotTransparent:0.4],
  } mutableCopy];

  if (styleProps.decorationLine == DecorationUnderline) {
    newAttrs[NSUnderlineStyleAttributeName] = @(NSUnderlineStyleSingle);
  }

  [_input->textView.textStorage addAttributes:newAttrs range:range];

  _blockMentionEditing = NO;
}

- (void)startMentionWithIndicator:(NSString *)indicator {
  NSRange currentRange = _input->textView.selectedRange;

  BOOL addSpaceBefore = NO;
  BOOL addSpaceAfter = NO;

  if (currentRange.location > 0) {
    unichar charBefore = [_input->textView.textStorage.string
        characterAtIndex:(currentRange.location - 1)];
    if (![[NSCharacterSet whitespaceAndNewlineCharacterSet]
            characterIsMember:charBefore]) {
      addSpaceBefore = YES;
    }
  }

  if (currentRange.location + currentRange.length <
      _input->textView.textStorage.string.length) {
    unichar charAfter = [_input->textView.textStorage.string
        characterAtIndex:(currentRange.location + currentRange.length)];
    if (![[NSCharacterSet whitespaceAndNewlineCharacterSet]
            characterIsMember:charAfter]) {
      addSpaceAfter = YES;
    }
  }

  NSString *finalString =
      [NSString stringWithFormat:@"%@%@%@", addSpaceBefore ? @" " : @"",
                                 indicator, addSpaceAfter ? @" " : @""];

  NSRange newSelect = NSMakeRange(
      currentRange.location + finalString.length + (addSpaceAfter ? -1 : 0), 0);

  if (currentRange.length == 0) {
    [TextInsertionUtils insertText:finalString
                                at:currentRange.location
              additionalAttributes:nullptr
                             input:_input
                     withSelection:NO];
  } else {
    [TextInsertionUtils replaceText:finalString
                                 at:currentRange
               additionalAttributes:nullptr
                              input:_input
                      withSelection:NO];
  }

  [_input->textView reactFocus];
  _input->textView.selectedRange = newSelect;
}

// handles removing no longer valid mentions
- (void)handleExistingMentions {
  // unfortunately whole text needs to be checked for them
  // checking the modified words doesn't work because mention's text can have
  // any number of spaces, which makes one mention any number of words long

  NSRange wholeText =
      NSMakeRange(0, _input->textView.textStorage.string.length);
  // get menntions in ascending range.location order
  NSArray<StylePair *> *mentions = [[self findAllOccurences:wholeText]
      sortedArrayUsingComparator:^NSComparisonResult(id _Nonnull obj1,
                                                     id _Nonnull obj2) {
        NSRange range1 = [((StylePair *)obj1).rangeValue rangeValue];
        NSRange range2 = [((StylePair *)obj2).rangeValue rangeValue];
        if (range1.location < range2.location) {
          return NSOrderedAscending;
        } else {
          return NSOrderedDescending;
        }
      }];

  // set of ranges to have their mentions removed - aren't valid anymore
  NSMutableSet<NSValue *> *rangesToRemove = [[NSMutableSet alloc] init];

  for (NSInteger i = 0; i < mentions.count; i++) {
    StylePair *mention = mentions[i];
    NSRange currentRange = [mention.rangeValue rangeValue];
    NSString *currentText = ((MentionParams *)mention.styleValue).text;
    // check locations with the previous mention if it exists - if they got
    // merged they need to be removed
    if (i > 0) {
      NSRange prevRange =
          [((StylePair *)mentions[i - 1]).rangeValue rangeValue];
      // mentions merged - both need to go out
      if (prevRange.location + prevRange.length == currentRange.location) {
        [rangesToRemove addObject:[NSValue valueWithRange:prevRange]];
        [rangesToRemove addObject:[NSValue valueWithRange:currentRange]];
        continue;
      }
    }

    // check for text, any modifications to it makes mention invalid
    NSString *existingText =
        [_input->textView.textStorage.string substringWithRange:currentRange];
    if (![existingText isEqualToString:currentText]) {
      [rangesToRemove addObject:[NSValue valueWithRange:currentRange]];
    }
  }

  for (NSValue *value in rangesToRemove) {
    [self removeAttributes:[value rangeValue]];
  }
}

// manages active mention range, which in turn emits proper onMention event
- (void)manageMentionEditing {
  // no actions performed when block is active
  if (_blockMentionEditing) {
    return;
  }

  // we don't take longer selections into consideration
  if (_input->textView.selectedRange.length > 0) {
    [self removeActiveMentionRange];
    return;
  }

  // get the text (and its range) that could be an editable mention
  NSArray *mentionCandidate = [self getMentionCandidate];
  if (mentionCandidate == nullptr) {
    [self removeActiveMentionRange];
    return;
  }
  NSString *candidateText = mentionCandidate[0];
  NSRange candidateRange = [(NSValue *)mentionCandidate[1] rangeValue];

  // get style classes that the mention shouldn't be recognized in, together
  // with other mentions
  NSArray *conflicts =
      _input->conflictingStyles[@([MentionStyle getStyleType])];
  NSArray *blocks = _input->blockingStyles[@([MentionStyle getStyleType])];
  NSArray *allConflicts = [[conflicts arrayByAddingObjectsFromArray:blocks]
      arrayByAddingObject:@([MentionStyle getStyleType])];
  BOOL conflictingStyle = NO;

  for (NSNumber *styleType in allConflicts) {
    id<BaseStyleProtocol> styleClass = _input->stylesDict[styleType];
    if (styleClass != nullptr && [styleClass anyOccurence:candidateRange]) {
      conflictingStyle = YES;
      break;
    }
  }

  // if any of the conflicting styles were present, don't edit the mention
  if (conflictingStyle) {
    [self removeActiveMentionRange];
    return;
  }

  // everything checks out - we are indeed editing a mention
  [self setActiveMentionRange:candidateRange text:candidateText];
}

// used to fix mentions' typing attributes
- (void)manageMentionTypingAttributes {
  // same as with links, mentions' typing attributes need to be constantly
  // removed whenever we are somewhere near
  BOOL removeAttrs = NO;
  MentionParams *params;

  if (_input->textView.selectedRange.length == 0) {
    // check before
    if (_input->textView.selectedRange.location >= 1) {
      if ([self detectStyle:NSMakeRange(
                                _input->textView.selectedRange.location - 1,
                                1)]) {
        removeAttrs = YES;
        params = [self
            getMentionParamsAt:_input->textView.selectedRange.location - 1];
      }
    }
    // check after
    if (_input->textView.selectedRange.location <
        _input->textView.textStorage.length) {
      if ([self detectStyle:NSMakeRange(_input->textView.selectedRange.location,
                                        1)]) {
        removeAttrs = YES;
        params =
            [self getMentionParamsAt:_input->textView.selectedRange.location];
      }
    }
  } else {
    if ([self anyOccurence:_input->textView.selectedRange]) {
      removeAttrs = YES;
    }
  }

  if (removeAttrs) {
    NSMutableDictionary *newTypingAttrs =
        [_input->textView.typingAttributes mutableCopy];
    newTypingAttrs[NSForegroundColorAttributeName] =
        [_input->config primaryColor];
    newTypingAttrs[NSUnderlineColorAttributeName] =
        [_input->config primaryColor];
    newTypingAttrs[NSStrikethroughColorAttributeName] =
        [_input->config primaryColor];
    [newTypingAttrs removeObjectForKey:NSBackgroundColorAttributeName];
    if ([self stylePropsWithParams:params].decorationLine ==
        DecorationUnderline) {
      [newTypingAttrs removeObjectForKey:NSUnderlineStyleAttributeName];
    }
    _input->textView.typingAttributes = newTypingAttrs;
  }
}

// replacing whole input (that starts with a mention) with a manually typed
// letter improperly applies mention's attributes to all the following text
- (BOOL)handleLeadingMentionReplacement:(NSRange)range
                        replacementText:(NSString *)text {
  // whole textView range gets replaced with a single letter
  if (_input->textView.textStorage.string.length > 0 &&
      NSEqualRanges(
          range, NSMakeRange(0, _input->textView.textStorage.string.length)) &&
      text.length == 1) {
    // first character detection is enough for the removal to be done
    if ([self detectStyle:NSMakeRange(0, 1)]) {
      [self
          removeAttributes:NSMakeRange(
                               0, _input->textView.textStorage.string.length)];
      // do the replacing manually
      [TextInsertionUtils replaceText:text
                                   at:range
                 additionalAttributes:nullptr
                                input:_input
                        withSelection:YES];
      return YES;
    }
  }
  return NO;
}

// returns mention params if it exists
- (MentionParams *)getMentionParamsAt:(NSUInteger)location {
  NSRange mentionRange = NSMakeRange(0, 0);
  NSRange inputRange = NSMakeRange(0, _input->textView.textStorage.length);

  // don't search at the very end of input
  NSUInteger searchLocation = location;
  if (searchLocation == _input->textView.textStorage.length) {
    return nullptr;
  }

  MentionParams *value =
      [_input->textView.textStorage attribute:MentionAttributeName
                                      atIndex:searchLocation
                        longestEffectiveRange:&mentionRange
                                      inRange:inputRange];
  return value;
}

- (NSValue *)getActiveMentionRange {
  return _activeMentionRange;
}

// returns full range of a mention at some location
- (NSRange)getFullMentionRangeAt:(NSUInteger)location {
  NSRange mentionRange = NSMakeRange(0, 0);
  NSRange inputRange = NSMakeRange(0, _input->textView.textStorage.length);

  // get the previous index if possible when at the very end of input
  NSUInteger searchLocation = location;
  if (searchLocation == _input->textView.textStorage.length) {
    if (searchLocation == 0) {
      return mentionRange;
    } else {
      searchLocation = searchLocation - 1;
    }
  }

  [_input->textView.textStorage attribute:MentionAttributeName
                                  atIndex:searchLocation
                    longestEffectiveRange:&mentionRange
                                  inRange:inputRange];
  return mentionRange;
}

// MARK: - Private non-standard methods

- (MentionStyleProps *)stylePropsWithParams:(MentionParams *)params {
  return [_input->config mentionStylePropsForIndicator:params.indicator];
}

// finds if any word/words around current selection are eligible to be edited as
// mentions since we allow for a single space inside an edited mention, we have
// take both current and the previous word into account
- (NSArray *)getMentionCandidate {
  NSDictionary *currentWord, *previousWord;
  NSString *currentWordText, *previousWordText, *finalText;
  NSValue *currentWordRange, *previousWordRange;
  NSRange finalRange;

  // word at the current selection
  currentWord = [WordsUtils getCurrentWord:_input->textView.textStorage.string
                                     range:_input->textView.selectedRange];
  if (currentWord != nullptr) {
    currentWordText = (NSString *)[currentWord objectForKey:@"word"];
    currentWordRange = (NSValue *)[currentWord objectForKey:@"range"];
  }

  if (currentWord != nullptr) {
    // current word exists
    unichar currentFirstChar = [currentWordText characterAtIndex:0];

    if ([[_input->config mentionIndicators]
            containsObject:@(currentFirstChar)]) {
      // current word exists and has a mention indicator; no need to check for
      // the previous word
      finalText = currentWordText;
      finalRange = [currentWordRange rangeValue];
    } else {
      // current word exists but no traces of mention indicator; get the
      // previous word

      NSInteger previousWordSearchLocation =
          [currentWordRange rangeValue].location - 1;
      if (previousWordSearchLocation < 0) {
        // previous word can't exist
        return nullptr;
      }

      unichar separatorChar = [_input->textView.textStorage.string
          characterAtIndex:previousWordSearchLocation];
      if (![[NSCharacterSet whitespaceCharacterSet]
              characterIsMember:separatorChar]) {
        // we want to check for the previous word ONLY if the separating
        // character was a space newlines don't make it
        return nullptr;
      }

      previousWord = [WordsUtils
          getCurrentWord:_input->textView.textStorage.string
                   range:NSMakeRange(previousWordSearchLocation, 0)];

      if (previousWord != nullptr) {
        // previous word exists; get its properties
        previousWordText = (NSString *)[previousWord objectForKey:@"word"];
        previousWordRange = (NSValue *)[previousWord objectForKey:@"range"];

        // check for the mention indicators in the previous word
        unichar previousFirstChar = [previousWordText characterAtIndex:0];

        if ([[_input->config mentionIndicators]
                containsObject:@(previousFirstChar)]) {
          // previous word has a proper mention indicator: treat both words as
          // an editable mention
          finalText = [NSString
              stringWithFormat:@"%@ %@", previousWordText, currentWordText];
          // range length is both words' lengths + 1 for a space between them
          finalRange =
              NSMakeRange([previousWordRange rangeValue].location,
                          [previousWordRange rangeValue].length +
                              [currentWordRange rangeValue].length + 1);
        } else {
          // neither current nor previous words have a mention indicator
          return nullptr;
        }
      } else {
        // previous word doesn't exist and no mention indicators in the current
        // word
        return nullptr;
      }
    }
  } else {
    // current word doesn't exist; try getting the previous one

    NSInteger previousWordSearchLocation =
        _input->textView.selectedRange.location - 1;
    if (previousWordSearchLocation < 0) {
      // previous word can't exist
      return nullptr;
    }

    unichar separatorChar = [_input->textView.textStorage.string
        characterAtIndex:previousWordSearchLocation];
    if (![[NSCharacterSet whitespaceCharacterSet]
            characterIsMember:separatorChar]) {
      // we want to check for the previous word ONLY if the separating character
      // was a space newlines don't make it
      return nullptr;
    }

    previousWord =
        [WordsUtils getCurrentWord:_input->textView.textStorage.string
                             range:NSMakeRange(previousWordSearchLocation, 0)];

    if (previousWord != nullptr) {
      // previous word exists; get its properties
      previousWordText = (NSString *)[previousWord objectForKey:@"word"];
      previousWordRange = (NSValue *)[previousWord objectForKey:@"range"];

      // check for the mention indicators in the previous word
      unichar previousFirstChar = [previousWordText characterAtIndex:0];

      if ([[_input->config mentionIndicators]
              containsObject:@(previousFirstChar)]) {
        // previous word has a proper mention indicator; treat previous word + a
        // space as a editable mention
        finalText = [NSString stringWithFormat:@"%@ ", previousWordText];
        // the range length is previous word length + 1 for a space
        finalRange = NSMakeRange([previousWordRange rangeValue].location,
                                 [previousWordRange rangeValue].length + 1);
      } else {
        // no current word, previous has no mention indicators
        return nullptr;
      }
    } else {
      // no current word, no previous word
      return nullptr;
    }
  }

  return @[ finalText, [NSValue valueWithRange:finalRange] ];
}

// both used for setting the active mention range + indicator and fires proper
// onMention event
- (void)setActiveMentionRange:(NSRange)range text:(NSString *)text {
  NSString *indicatorString =
      [NSString stringWithFormat:@"%C", [text characterAtIndex:0]];
  NSString *textString =
      [text substringWithRange:NSMakeRange(1, text.length - 1)];
  _activeMentionIndicator = indicatorString;
  _activeMentionRange = [NSValue valueWithRange:range];
  [_input emitOnMentionEvent:indicatorString text:textString];
}

// removes stored mention range + indicator, which means that we no longer edit
// a mention and onMention event gets fired
- (void)removeActiveMentionRange {
  if (_activeMentionIndicator != nullptr && _activeMentionRange != nullptr) {
    NSString *indicatorCopy = [_activeMentionIndicator copy];
    _activeMentionIndicator = nullptr;
    _activeMentionRange = nullptr;
    [_input emitOnMentionEvent:indicatorCopy text:nullptr];
  }
}

@end
