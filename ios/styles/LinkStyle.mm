#import "AttributeEntry.h"
#import "EnrichedTextInputView.h"
#import "LinkData.h"
#import "OccurenceUtils.h"
#import "StyleHeaders.h"
#import "TextInsertionUtils.h"
#import "UIView+React.h"
#import "WordsUtils.h"

static NSString *const ManualLinkAttributeName = @"EnrichedManualLink";
static NSString *const AutomaticLinkAttributeName = @"EnrichedAutomaticLink";

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

  NSMutableDictionary *newAttrs = [[NSMutableDictionary alloc] init];
  newAttrs[NSForegroundColorAttributeName] = [self.host.config linkColor];
  newAttrs[NSUnderlineColorAttributeName] = [self.host.config linkColor];
  newAttrs[NSStrikethroughColorAttributeName] = [self.host.config linkColor];
  if ([self.host.config linkDecorationLine] == DecorationUnderline) {
    newAttrs[NSUnderlineStyleAttributeName] = @(NSUnderlineStyleSingle);
  }
  [self.host.textView.textStorage addAttributes:newAttrs range:range];
}

- (void)reapplyFromStylePair:(StylePair *)pair {
  NSRange range = [pair.rangeValue rangeValue];
  LinkData *linkData = (LinkData *)pair.styleValue;

  if (linkData == nullptr) {
    return;
  }

  [self applyLinkMetaWithData:linkData range:range];
}

// we don't want the link to be extended, thus returning nullptr here.
- (AttributeEntry *)getEntryIfPresent:(NSRange)range {
  return nullptr;
}

- (void)toggle:(NSRange)range {
  // no-op for links
}

// we have to make sure all links in the range get fully removed here
- (void)remove:(NSRange)range withDirtyRange:(BOOL)withDirtyRange {
  NSArray<StylePair *> *links = [self all:range];
  [self.host.textView.textStorage beginEditing];
  for (StylePair *pair in links) {
    NSRange linkRange =
        [self getFullLinkRangeAt:[pair.rangeValue rangeValue].location];
    [self.host.textView.textStorage removeAttribute:ManualLinkAttributeName
                                              range:linkRange];
    [self.host.textView.textStorage removeAttribute:AutomaticLinkAttributeName
                                              range:linkRange];
    if (withDirtyRange) {
      [self.host.attributesManager addDirtyRange:linkRange];
    }
  }
  [self.host.textView.textStorage endEditing];
  [self removeLinkMetaFromTypingAttributes];
}

// used for conflicts, we have to remove the whole link
- (void)removeTyping {
  NSRange linkRange =
      [self getFullLinkRangeAt:self.host.textView.selectedRange.location];
  if (linkRange.length > 0) {
    [self.host.textView.textStorage beginEditing];
    [self.host.textView.textStorage removeAttribute:ManualLinkAttributeName
                                              range:linkRange];
    [self.host.textView.textStorage removeAttribute:AutomaticLinkAttributeName
                                              range:linkRange];
    [self.host.textView.textStorage endEditing];
    [self.host.attributesManager addDirtyRange:linkRange];
  }
  [self removeLinkMetaFromTypingAttributes];
}

- (BOOL)styleCondition:(id _Nullable)value range:(NSRange)range {
  LinkData *linkData = (LinkData *)value;
  return linkData != nullptr;
}

- (BOOL)detect:(NSRange)range {
  if (range.length >= 1) {
    BOOL onlyLinks = [OccurenceUtils
        detectMultiple:@[ ManualLinkAttributeName, AutomaticLinkAttributeName ]
              withHost:self.host
               inRange:range
         withCondition:^BOOL(id _Nullable value, NSRange subrange) {
           return [self styleCondition:value range:subrange];
         }];
    return onlyLinks ? [self isSingleLinkIn:range] : NO;
  }
  return [self getLinkDataAt:range.location] != nullptr;
}

- (BOOL)any:(NSRange)range {
  return [OccurenceUtils
        anyMultiple:@[ ManualLinkAttributeName, AutomaticLinkAttributeName ]
           withHost:self.host
            inRange:range
      withCondition:^BOOL(id _Nullable value, NSRange subrange) {
        return [self styleCondition:value range:subrange];
      }];
}

- (NSArray<StylePair *> *)all:(NSRange)range {
  return [OccurenceUtils
        allMultiple:@[ ManualLinkAttributeName, AutomaticLinkAttributeName ]
           withHost:self.host
            inRange:range
      withCondition:^BOOL(id _Nullable value, NSRange subrange) {
        return [self styleCondition:value range:subrange];
      }];
}

- (void)applyLinkMetaWithData:(LinkData *)linkData range:(NSRange)range {
  if (range.length == 0 || linkData.url == nullptr) {
    return;
  }
  NSString *key =
      linkData.isManual ? ManualLinkAttributeName : AutomaticLinkAttributeName;
  [self.host.textView.textStorage addAttribute:key
                                         value:[linkData copy]
                                         range:range];
}

- (void)removeLinkMetaFromTypingAttributes {
  NSMutableDictionary *newTypingAttrs =
      [self.host.textView.typingAttributes mutableCopy];
  [newTypingAttrs removeObjectForKey:ManualLinkAttributeName];
  [newTypingAttrs removeObjectForKey:AutomaticLinkAttributeName];
  self.host.textView.typingAttributes = newTypingAttrs;

  [self.host.attributesManager
      didRemoveTypingAttribute:ManualLinkAttributeName];
  [self.host.attributesManager
      didRemoveTypingAttribute:AutomaticLinkAttributeName];
}

- (void)addLink:(LinkData *)linkData
            range:(NSRange)range
    withSelection:(BOOL)withSelection {
  NSString *currentText =
      [self.host.textView.textStorage.string substringWithRange:range];

  NSString *key =
      linkData.isManual ? ManualLinkAttributeName : AutomaticLinkAttributeName;
  NSDictionary *metaAttrs = @{key : [linkData copy]};

  NSRange dirtyRange = NSMakeRange(0, 0);

  if (range.length == 0) {
    // insert link
    [TextInsertionUtils insertText:linkData.text
                                at:range.location
              additionalAttributes:metaAttrs
                             input:self.host
                     withSelection:withSelection];
    dirtyRange = NSMakeRange(range.location, linkData.text.length);
  } else if ([currentText isEqualToString:linkData.text]) {
    [self applyLinkMetaWithData:linkData range:range];
    dirtyRange = range;
    // TextInsertionUtils take care of the selection but here we have to
    // manually set it behind the link ONLY with manual links, automatic ones
    // don't need the selection fix
    if (linkData.isManual && withSelection) {
      [self.host.textView reactFocus];
      self.host.textView.selectedRange =
          NSMakeRange(range.location + linkData.text.length, 0);
    }
  } else {
    // replace text with link
    [TextInsertionUtils replaceText:linkData.text
                                 at:range
               additionalAttributes:metaAttrs
                              input:self.host
                      withSelection:withSelection];
    dirtyRange = NSMakeRange(range.location, linkData.text.length);
  }

  // add new dirty range
  [self.host.attributesManager addDirtyRange:dirtyRange];

  // mandatory connected links check
  NSDictionary *currentWord =
      [WordsUtils getCurrentWord:self.host.textView.textStorage.string
                           range:self.host.textView.selectedRange];
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
  NSRange inputRange = NSMakeRange(0, self.host.textView.textStorage.length);

  // don't search at the very end of input
  NSUInteger searchLocation = location;
  if (searchLocation == self.host.textView.textStorage.length) {
    return nullptr;
  }

  LinkData *manualData =
      [self.host.textView.textStorage attribute:ManualLinkAttributeName
                                        atIndex:searchLocation
                          longestEffectiveRange:&manualLinkRange
                                        inRange:inputRange];
  LinkData *automaticData =
      [self.host.textView.textStorage attribute:AutomaticLinkAttributeName
                                        atIndex:searchLocation
                          longestEffectiveRange:&automaticLinkRange
                                        inRange:inputRange];

  if ((manualData == nullptr && automaticData == nullptr) ||
      (manualLinkRange.length == 0 && automaticLinkRange.length == 0)) {
    return nullptr;
  }

  return manualData == nullptr ? automaticData : manualData;
}

// returns full range of a link at some location
- (NSRange)getFullLinkRangeAt:(NSUInteger)location {
  NSRange manualLinkRange = NSMakeRange(0, 0);
  NSRange automaticLinkRange = NSMakeRange(0, 0);
  NSRange inputRange = NSMakeRange(0, self.host.textView.textStorage.length);

  // get the previous index if possible when at the very end of input
  NSUInteger searchLocation = location;
  if (searchLocation == self.host.textView.textStorage.length) {
    if (searchLocation == 0) {
      return NSMakeRange(0, 0);
    }
    searchLocation = searchLocation - 1;
  }

  LinkData *manualData =
      [self.host.textView.textStorage attribute:ManualLinkAttributeName
                                        atIndex:searchLocation
                          longestEffectiveRange:&manualLinkRange
                                        inRange:inputRange];
  LinkData *automaticData =
      [self.host.textView.textStorage attribute:AutomaticLinkAttributeName
                                        atIndex:searchLocation
                          longestEffectiveRange:&automaticLinkRange
                                        inRange:inputRange];

  return manualData == nullptr
             ? automaticData == nullptr ? NSMakeRange(0, 0) : automaticLinkRange
             : manualLinkRange;
}

// handles detecting and removing automatic links
- (void)handleAutomaticLinks:(NSString *)word inRange:(NSRange)wordRange {
  LinkRegexConfig *linkRegexConfig = [self.host.config linkRegexConfig];

  // no automatic links with isDisabled
  if (linkRegexConfig.isDisabled) {
    return;
  }

  InlineCodeStyle *inlineCodeStyle =
      [self.host.stylesDict objectForKey:@([InlineCodeStyle getType])];
  MentionStyle *mentionStyle =
      [self.host.stylesDict objectForKey:@([MentionStyle getType])];
  CodeBlockStyle *codeBlockStyle =
      [self.host.stylesDict objectForKey:@([CodeBlockStyle getType])];

  // we don't recognize links along mentions, inline code or codeblocks
  if (mentionStyle != nullptr && [mentionStyle any:wordRange]) {
    return;
  }
  if (inlineCodeStyle != nullptr && [inlineCodeStyle any:wordRange]) {
    return;
  }
  if (codeBlockStyle != nullptr && [codeBlockStyle any:wordRange]) {
    return;
  }

  // remove connected different links
  [self removeConnectedLinksIfNeeded:word range:wordRange];

  // we don't recognize automatic links along manual ones
  __block BOOL manualLinkPresent = NO;
  [self.host.textView.textStorage
      enumerateAttribute:ManualLinkAttributeName
                 inRange:wordRange
                 options:0
              usingBlock:^(id value, NSRange subrange, BOOL *stop) {
                if ([self styleCondition:value range:subrange]) {
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
    NSRegularExpression *userRegex = [self.host.config parsedLinkRegex];

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
      LinkData *newData = [[LinkData alloc] init];
      newData.text = word;
      newData.url = regexPassedUrl;
      newData.isManual = NO;

      [self addLink:newData range:wordRange withSelection:NO];

      // emit onLinkDetected if style was added
      [(id)self.host emitOnLinkDetectedEvent:newData range:wordRange];
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
  __block LinkData *manualLinkMinValue = nullptr;
  __block LinkData *manualLinkMaxValue = nullptr;
  __block NSInteger manualLinkMinIdx = -1;
  __block NSInteger manualLinkMaxIdx = -1;

  [self.host.textView.textStorage
      enumerateAttribute:ManualLinkAttributeName
                 inRange:wordRange
                 options:0
              usingBlock:^(id value, NSRange range, BOOL *stop) {
                LinkData *linkDataValue = (LinkData *)value;
                if (linkDataValue != nullptr) {
                  NSInteger linkMin = range.location;
                  NSInteger linkMax = range.location + range.length - 1;
                  if (manualLinkMinIdx == -1 || linkMin < manualLinkMinIdx) {
                    manualLinkMinIdx = linkMin;
                    manualLinkMinValue = linkDataValue;
                  }
                  if (manualLinkMaxIdx == -1 || linkMax > manualLinkMaxIdx) {
                    manualLinkMaxIdx = linkMax;
                    manualLinkMaxValue = linkDataValue;
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
  if ([manualLinkMinValue isEqualToLinkData:manualLinkMaxValue]) {
    NSRange newRange =
        NSMakeRange(manualLinkMinIdx, manualLinkMaxIdx - manualLinkMinIdx + 1);
    [self applyLinkMetaWithData:manualLinkMinValue range:newRange];
    [self.host.attributesManager addDirtyRange:newRange];
  }
}

// MARK: - Private non-standard methods

// determines whether a given range contains only links pointing to one url
// assumes the whole range is links only already
- (BOOL)isSingleLinkIn:(NSRange)range {
  return [self all:range].count == 1;
}

- (void)removeConnectedLinksIfNeeded:(NSString *)word range:(NSRange)wordRange {
  BOOL anyAutomatic =
      [OccurenceUtils any:AutomaticLinkAttributeName
                 withHost:self.host
                  inRange:wordRange
            withCondition:^BOOL(id _Nullable value, NSRange subrange) {
              return [self styleCondition:value range:subrange];
            }];
  BOOL anyManual =
      [OccurenceUtils any:ManualLinkAttributeName
                 withHost:self.host
                  inRange:wordRange
            withCondition:^BOOL(id _Nullable value, NSRange subrange) {
              return [self styleCondition:value range:subrange];
            }];

  // both manual and automatic links are somewhere - delete!
  if (anyAutomatic && anyManual) {
    [self remove:wordRange withDirtyRange:YES];
  }

  // we are now sure there is only one type of link there - and make sure it
  // covers the whole word
  BOOL onlyLinks = [OccurenceUtils
      detectMultiple:@[ ManualLinkAttributeName, AutomaticLinkAttributeName ]
            withHost:self.host
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
