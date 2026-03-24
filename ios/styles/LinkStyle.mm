#import "AttributeEntry.h"
#import "EnrichedTextInputView.h"
#import "LinkData.h"
#import "OccurenceUtils.h"
#import "StyleHeaders.h"
#import "TextInsertionUtils.h"
#import "UIView+React.h"
#import "WordsUtils.h"

static NSString *const ManualLinkAttributeName = @"ManualLinkAttributeName";
static NSString *const AutomaticLinkAttributeName =
    @"AutomaticLinkAttributeName";

@implementation LinkStyle

+ (StyleType)getType {
  return Link;
}

- (NSString *)getKey {
  return ManualLinkAttributeName;
}

- (BOOL)isParagraph {
  return NO;
}

- (void)applyStyling:(NSRange)range {
  LinkData *data = [self getLinkDataAt:range.location];
  if (data == nullptr || data.url == nullptr) {
    return;
  }

  NSMutableDictionary<NSAttributedStringKey, id> *newAttrs =
      [[NSMutableDictionary<NSAttributedStringKey, id> alloc] init];
  newAttrs[NSForegroundColorAttributeName] = [self.input->config linkColor];
  newAttrs[NSUnderlineColorAttributeName] = [self.input->config linkColor];
  newAttrs[NSStrikethroughColorAttributeName] = [self.input->config linkColor];
  if ([self.input->config linkDecorationLine] == DecorationUnderline) {
    newAttrs[NSUnderlineStyleAttributeName] = @(NSUnderlineStyleSingle);
  }
  [self.input->textView.textStorage addAttributes:newAttrs range:range];
}

- (void)reapplyAttributesFromStylePair:(StylePair *)pair {
  NSRange range = [pair.rangeValue rangeValue];
  NSString *url = nullptr;
  BOOL manual = YES;
  id styleValue = pair.styleValue;
  if ([styleValue isKindOfClass:[LinkData class]]) {
    LinkData *linkData = (LinkData *)styleValue;
    url = linkData.url;
    manual = linkData.text == nullptr
                 ? YES
                 : ![linkData.text isEqualToString:linkData.url];
  } else if ([styleValue isKindOfClass:[NSString class]]) {
    url = (NSString *)styleValue;
    NSString *textInRange =
        [self.input->textView.textStorage.string substringWithRange:range];
    manual = ![textInRange isEqualToString:url];
  }
  if (url == nullptr) {
    return;
  }
  [self applyLinkMetaForUrl:url manual:manual range:range];
}

- (AttributeEntry *)getEntryIfPresent:(NSRange)range {
  return nullptr;
}

- (void)toggle:(NSRange)range {
  // no-op for links
}

// we have to make sure all links in the range get fully removed here
- (void)remove:(NSRange)range withDirtyRange:(BOOL)withDirtyRange {
  NSArray<StylePair *> *links = [self all:range];
  [self.input->textView.textStorage beginEditing];
  for (StylePair *pair in links) {
    NSRange linkRange =
        [self getFullLinkRangeAt:[pair.rangeValue rangeValue].location];
    [self.input->textView.textStorage removeAttribute:ManualLinkAttributeName
                                                range:linkRange];
    [self.input->textView.textStorage removeAttribute:AutomaticLinkAttributeName
                                                range:linkRange];
    if (withDirtyRange) {
      [self.input->attributesManager addDirtyRange:linkRange];
    }
  }
  [self.input->textView.textStorage endEditing];
  [self removeLinkMetaFromTypingAttributes];
}

// used for conflicts, we have to remove the whole link
- (void)removeTyping {
  NSRange linkRange =
      [self getFullLinkRangeAt:self.input->textView.selectedRange.location];
  if (linkRange.length > 0) {
    [self.input->textView.textStorage beginEditing];
    [self.input->textView.textStorage removeAttribute:ManualLinkAttributeName
                                                range:linkRange];
    [self.input->textView.textStorage removeAttribute:AutomaticLinkAttributeName
                                                range:linkRange];
    [self.input->textView.textStorage endEditing];
    [self.input->attributesManager addDirtyRange:linkRange];
  }
  [self removeLinkMetaFromTypingAttributes];
}

- (BOOL)styleCondition:(id _Nullable)value range:(NSRange)range {
  NSString *linkValue = (NSString *)value;
  return linkValue != nullptr;
}

- (BOOL)detect:(NSRange)range {
  if (range.length >= 1) {
    BOOL onlyLinks = [OccurenceUtils
        detectMultiple:@[ ManualLinkAttributeName, AutomaticLinkAttributeName ]
             withInput:self.input
               inRange:range
         withCondition:^BOOL(id _Nullable value, NSRange r) {
           return [self styleCondition:value range:r];
         }];
    return onlyLinks ? [self isSingleLinkIn:range] : NO;
  }
  return [self getLinkDataAt:range.location] != nullptr;
}

- (BOOL)any:(NSRange)range {
  return [OccurenceUtils
        anyMultiple:@[ ManualLinkAttributeName, AutomaticLinkAttributeName ]
          withInput:self.input
            inRange:range
      withCondition:^BOOL(id _Nullable value, NSRange r) {
        return [self styleCondition:value range:r];
      }];
}

- (NSArray<StylePair *> *)all:(NSRange)range {
  return [OccurenceUtils
        allMultiple:@[ ManualLinkAttributeName, AutomaticLinkAttributeName ]
          withInput:self.input
            inRange:range
      withCondition:^BOOL(id _Nullable value, NSRange r) {
        return [self styleCondition:value range:r];
      }];
}

- (void)applyLinkMetaForUrl:(NSString *)url
                     manual:(BOOL)manual
                      range:(NSRange)range {
  if (range.length == 0 || url == nullptr) {
    return;
  }
  NSString *key = manual ? ManualLinkAttributeName : AutomaticLinkAttributeName;
  [self.input->textView.textStorage addAttribute:key
                                           value:[url copy]
                                           range:range];
}

- (void)removeLinkMetaFromTypingAttributes {
  NSMutableDictionary *newTypingAttrs =
      [self.input->textView.typingAttributes mutableCopy];
  [newTypingAttrs removeObjectForKey:ManualLinkAttributeName];
  [newTypingAttrs removeObjectForKey:AutomaticLinkAttributeName];
  self.input->textView.typingAttributes = newTypingAttrs;

  [self.input->attributesManager
      didRemoveTypingAttribute:ManualLinkAttributeName];
  [self.input->attributesManager
      didRemoveTypingAttribute:AutomaticLinkAttributeName];
}

- (void)addLink:(NSString *)text
              url:(NSString *)url
            range:(NSRange)range
           manual:(BOOL)manual
    withSelection:(BOOL)withSelection {
  NSString *currentText =
      [self.input->textView.textStorage.string substringWithRange:range];

  NSString *key = manual ? ManualLinkAttributeName : AutomaticLinkAttributeName;
  NSDictionary<NSAttributedStringKey, id> *metaAttrs = @{key : [url copy]};

  NSRange dirtyRange = range;

  if (range.length == 0) {
    // insert link
    [TextInsertionUtils insertText:text
                                at:range.location
              additionalAttributes:metaAttrs
                             input:self.input
                     withSelection:withSelection];
    dirtyRange = NSMakeRange(range.location, text.length);
  } else if ([currentText isEqualToString:text]) {
    [self applyLinkMetaForUrl:url manual:manual range:range];
    dirtyRange = range;
    // TextInsertionUtils take care of the selection but here we have to
    // manually set it behind the link ONLY with manual links, automatic ones
    // don't need the selection fix
    if (manual && withSelection) {
      [self.input->textView reactFocus];
      self.input->textView.selectedRange =
          NSMakeRange(range.location + text.length, 0);
    }
  } else {
    // replace text with link
    [TextInsertionUtils replaceText:text
                                 at:range
               additionalAttributes:metaAttrs
                              input:self.input
                      withSelection:withSelection];
    dirtyRange = NSMakeRange(range.location, text.length);
  }

  if (dirtyRange.length > 0) {
    [self.input->attributesManager addDirtyRange:dirtyRange];
  }

  // mandatory connected links check
  NSDictionary *currentWord =
      [WordsUtils getCurrentWord:self.input->textView.textStorage.string
                           range:self.input->textView.selectedRange];
  if (currentWord != nullptr) {
    // get word properties
    NSString *wordText = (NSString *)[currentWord objectForKey:@"word"];
    NSValue *wordRangeValue = (NSValue *)[currentWord objectForKey:@"range"];
    if (wordText != nullptr && wordRangeValue != nullptr) {
      [self removeConnectedLinksIfNeeded:wordText
                                   range:[wordRangeValue rangeValue]];
    }
  }
}

// get exact link data at the given location if it exists
- (LinkData *)getLinkDataAt:(NSUInteger)location {
  NSRange manualLinkRange = NSMakeRange(0, 0);
  NSRange automaticLinkRange = NSMakeRange(0, 0);
  NSRange inputRange = NSMakeRange(0, self.input->textView.textStorage.length);

  // don't search at the very end of input
  NSUInteger searchLocation = location;
  if (searchLocation == self.input->textView.textStorage.length) {
    return nullptr;
  }

  NSString *manualUrl =
      [self.input->textView.textStorage attribute:ManualLinkAttributeName
                                          atIndex:searchLocation
                            longestEffectiveRange:&manualLinkRange
                                          inRange:inputRange];
  NSString *automaticUrl =
      [self.input->textView.textStorage attribute:AutomaticLinkAttributeName
                                          atIndex:searchLocation
                            longestEffectiveRange:&automaticLinkRange
                                          inRange:inputRange];

  if ((manualUrl == nullptr && automaticUrl == nullptr) ||
      (manualLinkRange.length == 0 && automaticLinkRange.length == 0)) {
    return nullptr;
  }

  NSString *linkUrl = manualUrl == nullptr ? automaticUrl : manualUrl;
  NSRange linkRange =
      manualUrl == nullptr ? automaticLinkRange : manualLinkRange;

  LinkData *data = [[LinkData alloc] init];
  data.url = linkUrl;
  data.text =
      [self.input->textView.textStorage.string substringWithRange:linkRange];
  return data;
}

// returns full range of a link at some location
- (NSRange)getFullLinkRangeAt:(NSUInteger)location {
  NSRange manualLinkRange = NSMakeRange(0, 0);
  NSRange automaticLinkRange = NSMakeRange(0, 0);
  NSRange inputRange = NSMakeRange(0, self.input->textView.textStorage.length);

  // get the previous index if possible when at the very end of input
  NSUInteger searchLocation = location;
  if (searchLocation == self.input->textView.textStorage.length) {
    if (searchLocation == 0) {
      return NSMakeRange(0, 0);
    }
    searchLocation = searchLocation - 1;
  }

  NSString *manualLink =
      [self.input->textView.textStorage attribute:ManualLinkAttributeName
                                          atIndex:searchLocation
                            longestEffectiveRange:&manualLinkRange
                                          inRange:inputRange];
  NSString *automaticLink =
      [self.input->textView.textStorage attribute:AutomaticLinkAttributeName
                                          atIndex:searchLocation
                            longestEffectiveRange:&automaticLinkRange
                                          inRange:inputRange];

  return manualLink == nullptr
             ? automaticLink == nullptr ? NSMakeRange(0, 0) : automaticLinkRange
             : manualLinkRange;
}

// handles detecting and removing automatic links
- (void)handleAutomaticLinks:(NSString *)word inRange:(NSRange)wordRange {
  LinkRegexConfig *linkRegexConfig = [self.input->config linkRegexConfig];

  // no automatic links with isDisabled
  if (linkRegexConfig.isDisabled) {
    return;
  }

  InlineCodeStyle *inlineCodeStyle =
      [self.input->stylesDict objectForKey:@([InlineCodeStyle getType])];
  MentionStyle *mentionStyle =
      [self.input->stylesDict objectForKey:@([MentionStyle getType])];
  CodeBlockStyle *codeBlockStyle =
      [self.input->stylesDict objectForKey:@([CodeBlockStyle getType])];

  if (inlineCodeStyle == nullptr || mentionStyle == nullptr) {
    return;
  }

  // we don't recognize links along mentions
  if ([mentionStyle any:wordRange]) {
    return;
  }

  // we don't recognize links among inline code
  if ([inlineCodeStyle any:wordRange]) {
    return;
  }

  // we don't recognize links in codeblocks
  if ([codeBlockStyle any:wordRange]) {
    return;
  }

  // remove connected different links
  [self removeConnectedLinksIfNeeded:word range:wordRange];

  // we don't recognize automatic links along manual ones
  __block BOOL manualLinkPresent = NO;
  [self.input->textView.textStorage
      enumerateAttribute:ManualLinkAttributeName
                 inRange:wordRange
                 options:0
              usingBlock:^(id value, NSRange r, BOOL *stop) {
                NSString *urlValue = (NSString *)value;
                if (urlValue != nullptr) {
                  manualLinkPresent = YES;
                  *stop = YES;
                }
              }];
  if (manualLinkPresent) {
    return;
  }

  // all conditions are met; try matching the word to a proper regex

  NSString *regexPassedUrl = nullptr;
  NSRange matchingRange = NSMakeRange(0, word.length);

  if (linkRegexConfig.isDefault) {
    // use default regex
    regexPassedUrl = [self tryMatchingDefaultLinkRegex:word
                                            matchRange:matchingRange];
  } else {
    // use user defined regex if it exists
    NSRegularExpression *userRegex = [self.input->config parsedLinkRegex];

    if (userRegex == nullptr) {
      // fallback to default regex
      regexPassedUrl = [self tryMatchingDefaultLinkRegex:word
                                              matchRange:matchingRange];
    } else if ([userRegex numberOfMatchesInString:word
                                          options:0
                                            range:matchingRange]) {
      regexPassedUrl = word;
    }
  }

  if (regexPassedUrl != nullptr) {
    // add style only if needed
    BOOL addStyle = YES;
    if ([self detect:wordRange]) {
      LinkData *currentData = [self getLinkDataAt:wordRange.location];
      if (currentData != nullptr && currentData.url != nullptr &&
          [currentData.url isEqualToString:regexPassedUrl]) {
        addStyle = NO;
      }
    }
    if (addStyle) {
      [self addLink:word
                    url:regexPassedUrl
                  range:wordRange
                 manual:NO
          withSelection:NO];
      // emit onLinkDetected if style was added
      [self.input emitOnLinkDetectedEvent:word
                                      url:regexPassedUrl
                                    range:wordRange];
    }
  } else if ([self any:wordRange]) {
    // there was some automatic link (because anyOccurence is true and we are
    // sure there are no manual links) still, it didn't pass any regex - needs
    // to be removed
    [self remove:wordRange withDirtyRange:YES];
  }
}

- (NSString *)tryMatchingDefaultLinkRegex:(NSString *)word
                               matchRange:(NSRange)range {
  if ([[LinkStyle fullRegex] numberOfMatchesInString:word
                                             options:0
                                               range:range] ||
      [[LinkStyle wwwRegex] numberOfMatchesInString:word
                                            options:0
                                              range:range] ||
      [[LinkStyle bareRegex] numberOfMatchesInString:word
                                             options:0
                                               range:range]) {
    return word;
  }

  return nullptr;
}

// handles refreshing manual links
- (void)handleManualLinks:(NSString *)word inRange:(NSRange)wordRange {
  // look for manual links within the word
  __block NSString *manualLinkMinValue = @"";
  __block NSString *manualLinkMaxValue = @"";
  __block NSInteger manualLinkMinIdx = -1;
  __block NSInteger manualLinkMaxIdx = -1;

  [self.input->textView.textStorage
      enumerateAttribute:ManualLinkAttributeName
                 inRange:wordRange
                 options:0
              usingBlock:^(id value, NSRange range, BOOL *stop) {
                NSString *urlValue = (NSString *)value;
                if (urlValue != nullptr) {
                  NSInteger linkMin = range.location;
                  NSInteger linkMax = range.location + range.length - 1;
                  if (manualLinkMinIdx == -1 || linkMin < manualLinkMinIdx) {
                    manualLinkMinIdx = linkMin;
                    manualLinkMinValue = value;
                  }
                  if (manualLinkMaxIdx == -1 || linkMax > manualLinkMaxIdx) {
                    manualLinkMaxIdx = linkMax;
                    manualLinkMaxValue = value;
                  }
                }
              }];

  // no manual links
  if (manualLinkMinIdx == -1 || manualLinkMaxIdx == -1) {
    return;
  }

  // heuristic for refreshing manual links:
  // we update the Manual attribute between the bounds of existing ones
  // we do that only if the bounds point to the same url
  // this way manual link gets "extended" only if some characters were added
  // inside it
  if ([manualLinkMinValue isEqualToString:manualLinkMaxValue]) {
    NSRange newRange =
        NSMakeRange(manualLinkMinIdx, manualLinkMaxIdx - manualLinkMinIdx + 1);
    [self applyLinkMetaForUrl:manualLinkMinValue manual:YES range:newRange];
    if (newRange.length > 0) {
      [self.input->attributesManager addDirtyRange:newRange];
    }
  }
}

// replacing whole input (that starts with a link) with a manually typed letter
// improperly applies link's attributes to all the following text
- (BOOL)handleLeadingLinkReplacement:(NSRange)range
                     replacementText:(NSString *)text {
  // whole textView range gets replaced with a single letter
  if (self.input->textView.textStorage.string.length > 0 &&
      NSEqualRanges(
          range,
          NSMakeRange(0, self.input->textView.textStorage.string.length)) &&
      text.length == 1) {
    // first character detection is enough for the removal to be done
    if ([self detect:NSMakeRange(0, 1)]) {
      [self remove:NSMakeRange(0,
                               self.input->textView.textStorage.string.length)
          withDirtyRange:YES];
      // do the replacing manually
      [TextInsertionUtils replaceText:text
                                   at:range
                 additionalAttributes:nullptr
                                input:self.input
                        withSelection:YES];
      return YES;
    }
  }
  return NO;
}

// MARK: - Private non-standard methods

// determines whether a given range contains only links pointing to one url
// assumes the whole range is links only already
- (BOOL)isSingleLinkIn:(NSRange)range {
  return [self all:range].count == 1;
}

- (void)removeConnectedLinksIfNeeded:(NSString *)word range:(NSRange)wordRange {
  BOOL anyAutomatic = [OccurenceUtils any:AutomaticLinkAttributeName
                                withInput:self.input
                                  inRange:wordRange
                            withCondition:^BOOL(id _Nullable value, NSRange r) {
                              return [self styleCondition:value range:r];
                            }];
  BOOL anyManual = [OccurenceUtils any:ManualLinkAttributeName
                             withInput:self.input
                               inRange:wordRange
                         withCondition:^BOOL(id _Nullable value, NSRange r) {
                           return [self styleCondition:value range:r];
                         }];

  // both manual and automatic links are somewhere - delete!
  if (anyAutomatic && anyManual) {
    [self remove:wordRange withDirtyRange:YES];
  }

  // we are now sure there is only one type of link there - and make sure it
  // covers the whole word
  BOOL onlyLinks = [OccurenceUtils
      detectMultiple:@[ ManualLinkAttributeName, AutomaticLinkAttributeName ]
           withInput:self.input
             inRange:wordRange
       withCondition:^BOOL(id _Nullable value, NSRange r) {
         return [self styleCondition:value range:r];
       }];

  // only one link might be present!
  if (onlyLinks && ![self isSingleLinkIn:wordRange]) {
    [self remove:wordRange withDirtyRange:YES];
  }
}

+ (NSRegularExpression *)fullRegex {
  static NSRegularExpression *regex;
  static dispatch_once_t onceToken;
  dispatch_once(&onceToken, ^{
    regex =
        [NSRegularExpression regularExpressionWithPattern:
                                 @"http(s)?:\\/\\/"
                                 @"www\\.[-a-zA-Z0-9@:%._\\+~#=]{1,256}\\.[a-"
                                 @"z]{2,6}\\b([-a-zA-Z0-9@:%_\\+.~#?&//=]*)"
                                                  options:0
                                                    error:nullptr];
  });
  return regex;
}

+ (NSRegularExpression *)wwwRegex {
  static NSRegularExpression *regex;
  static dispatch_once_t onceToken;
  dispatch_once(&onceToken, ^{
    regex =
        [NSRegularExpression regularExpressionWithPattern:
                                 @"www\\.[-a-zA-Z0-9@:%._\\+~#=]{1,256}\\.[a-"
                                 @"z]{2,6}\\b([-a-zA-Z0-9@:%_\\+.~#?&//=]*)"
                                                  options:0
                                                    error:nullptr];
  });
  return regex;
}

+ (NSRegularExpression *)bareRegex {
  static NSRegularExpression *regex;
  static dispatch_once_t onceToken;
  dispatch_once(&onceToken, ^{
    regex =
        [NSRegularExpression regularExpressionWithPattern:
                                 @"[-a-zA-Z0-9@:%._\\+~#=]{1,256}\\.[a-z]{2,"
                                 @"6}\\b([-a-zA-Z0-9@:%_\\+.~#?&//=]*)"
                                                  options:0
                                                    error:nullptr];
  });
  return regex;
}

@end
