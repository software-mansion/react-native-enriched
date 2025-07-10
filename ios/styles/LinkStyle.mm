#import "StyleHeaders.h"
#import "ReactNativeRichTextEditorView.h"
#import "OccurenceUtils.h"
#import "TextInsertionUtils.h"
#import "UIView+React.h"
#import "WordsUtils.h"

// custom NSAttributedStringKeys to differentiate manually added and automatically detected links
static NSString *const ManualLinkAttributeName = @"ManualLinkAttributeName";
static NSString *const AutomaticLinkAttributeName = @"AutomaticLinkAttributeName";

@implementation LinkStyle {
  ReactNativeRichTextEditorView *_editor;
}

+ (StyleType)getStyleType { return Link; }

- (instancetype)initWithEditor:(id)editor {
  self = [super init];
  _editor = (ReactNativeRichTextEditorView *) editor;
  return self;
}

- (void)applyStyle:(NSRange)range {
  // no-op for links
}

- (void)addAttributes:(NSRange)range {
  // no-op for links
}

- (void)addTypingAttributes {
  // no-op for links
}

// we have to make sure all links in the range get fully removed here
- (void)removeAttributes:(NSRange)range {
  NSArray<StylePair *> *links = [self findAllOccurences:range];
  [_editor->textView.textStorage beginEditing];
  for(StylePair *pair in links) {
    NSRange linkRange = [self getFullLinkRangeAt:[pair.rangeValue rangeValue].location];
    [_editor->textView.textStorage removeAttribute:ManualLinkAttributeName range:linkRange];
    [_editor->textView.textStorage removeAttribute:AutomaticLinkAttributeName range:linkRange];
    [_editor->textView.textStorage addAttribute:NSForegroundColorAttributeName value:[_editor->config primaryColor] range:linkRange];
    [_editor->textView.textStorage addAttribute:NSUnderlineColorAttributeName value:[_editor->config primaryColor] range:linkRange];
    if([_editor->config linkDecorationLine] == DecorationUnderline) {
      [_editor->textView.textStorage removeAttribute:NSUnderlineStyleAttributeName range:linkRange];
    }
  }
  [_editor->textView.textStorage endEditing];
  
  // adjust typing attributes as well
  NSMutableDictionary *newTypingAttrs = [_editor->textView.typingAttributes mutableCopy];
  newTypingAttrs[NSForegroundColorAttributeName] = [_editor->config primaryColor];
  newTypingAttrs[NSUnderlineColorAttributeName] = [_editor->config primaryColor];
  if([_editor->config linkDecorationLine] == DecorationUnderline) {
    [newTypingAttrs removeObjectForKey:NSUnderlineStyleAttributeName];
  }
  _editor->textView.typingAttributes = newTypingAttrs;
}

// used for conflicts, we have to remove the whole link
- (void)removeTypingAttributes {
  NSRange linkRange = [self getFullLinkRangeAt:_editor->textView.selectedRange.location];
  [_editor->textView.textStorage beginEditing];
  [_editor->textView.textStorage removeAttribute:ManualLinkAttributeName range:linkRange];
  [_editor->textView.textStorage removeAttribute:AutomaticLinkAttributeName range:linkRange];
  [_editor->textView.textStorage addAttribute:NSForegroundColorAttributeName value:[_editor->config primaryColor] range:linkRange];
  [_editor->textView.textStorage addAttribute:NSUnderlineColorAttributeName value:[_editor->config primaryColor] range:linkRange];
  if([_editor->config linkDecorationLine] == DecorationUnderline) {
    [_editor->textView.textStorage removeAttribute:NSUnderlineStyleAttributeName range:linkRange];
  }
  [_editor->textView.textStorage endEditing];
  
  // adjust typing attributes as well
  NSMutableDictionary *newTypingAttrs = [_editor->textView.typingAttributes mutableCopy];
  newTypingAttrs[NSForegroundColorAttributeName] = [_editor->config primaryColor];
  newTypingAttrs[NSUnderlineColorAttributeName] = [_editor->config primaryColor];
  if([_editor->config linkDecorationLine] == DecorationUnderline) {
    [newTypingAttrs removeObjectForKey:NSUnderlineStyleAttributeName];
  }
  _editor->textView.typingAttributes = newTypingAttrs;
}

- (BOOL)styleCondition:(id _Nullable)value :(NSRange)range {
  NSString *linkValue = (NSString *)value;
  return linkValue != nullptr;
}

- (BOOL)detectStyle:(NSRange)range {
  if(range.length >= 1) {
    BOOL onlyLinks = [OccurenceUtils detectMultiple:@[ManualLinkAttributeName, AutomaticLinkAttributeName] withEditor:_editor inRange:range
      withCondition: ^BOOL(id  _Nullable value, NSRange range) {
        return [self styleCondition:value :range];
      }
    ];
    return onlyLinks ? [self isSingleLinkIn:range] : NO;
  } else {
    return [self getLinkDataAt:range.location] != nullptr;
  }
}

- (BOOL)anyOccurence:(NSRange)range {
  return [OccurenceUtils anyMultiple:@[ManualLinkAttributeName, AutomaticLinkAttributeName] withEditor:_editor inRange:range
    withCondition:^BOOL(id  _Nullable value, NSRange range) {
      return [self styleCondition:value :range];
    }
  ];
}

- (NSArray<StylePair *> *_Nullable)findAllOccurences:(NSRange)range {
  return [OccurenceUtils allMultiple:@[ManualLinkAttributeName, AutomaticLinkAttributeName] withEditor:_editor inRange:range
    withCondition:^BOOL(id  _Nullable value, NSRange range) {
      return [self styleCondition:value :range];
    }
  ];
}

// MARK: - Public non-standard methods

- (void)addLink:(NSString*)text url:(NSString*)url range:(NSRange)range manual:(BOOL)manual {
  NSString *currentText = [_editor->textView.textStorage.string substringWithRange:range];
  
  NSMutableDictionary<NSAttributedStringKey, id> *newAttrs = [[NSMutableDictionary<NSAttributedStringKey, id> alloc] init];
  newAttrs[NSForegroundColorAttributeName] = [_editor->config linkColor];
  newAttrs[NSUnderlineColorAttributeName] = [_editor->config linkColor];
  if([_editor->config linkDecorationLine] == DecorationUnderline) {
    newAttrs[NSUnderlineStyleAttributeName] = @(NSUnderlineStyleSingle);
  }
  if(manual) {
    newAttrs[ManualLinkAttributeName] = [url copy];
  } else {
    newAttrs[AutomaticLinkAttributeName] = [url copy];
  }
  
  if(range.length == 0) {
    // insert link
    [TextInsertionUtils insertText:text inView:_editor->textView at:range.location additionalAttributes:newAttrs];
  } else if([currentText isEqualToString:text]) {
    // apply link attributes
    [_editor->textView.textStorage addAttributes:newAttrs range:range];
    // TextInsertionUtils take care of the selection but here we have to manually set it behind the link
    // ONLY with manual links, automatic ones don't need the selection fix
    if(manual) {
      [_editor->textView reactFocus];
      _editor->textView.selectedRange = NSMakeRange(range.location + text.length, 0);
    }
  } else {
    // replace text with link
    [TextInsertionUtils replaceText:text inView:_editor->textView at:range additionalAttributes:newAttrs];
  }
  
  // mandatory connected links check
  NSDictionary *currentWord = [WordsUtils getCurrentWord:_editor->textView.textStorage.string range:_editor->textView.selectedRange];
  if(currentWord != nullptr) {
    // get word properties
    NSString *wordText = (NSString *)[currentWord objectForKey:@"word"];
    NSValue *wordRangeValue = (NSValue *)[currentWord objectForKey:@"range"];
    if(wordText != nullptr && wordRangeValue != nullptr) {
      [self removeConnectedLinksIfNeeded:wordText range:[wordRangeValue rangeValue]];
    }
  }
  
  [self manageLinkTypingAttributes];
  
  // run the editor changes callback
  [_editor anyTextMayHaveBeenModified];
}

// get exact link data at the given location if it exists
- (LinkData *)getLinkDataAt:(NSUInteger)location {
  NSRange manualLinkRange = NSMakeRange(0, 0);
  NSRange automaticLinkRange = NSMakeRange(0, 0);
  NSRange editorRange = NSMakeRange(0, _editor->textView.textStorage.length);
  
  // don't search at the very end of input
  NSUInteger searchLocation = location;
  if(searchLocation == _editor->textView.textStorage.length) {
    return nullptr;
  }
  
  NSString *manualUrl = [_editor->textView.textStorage
    attribute:ManualLinkAttributeName
    atIndex:searchLocation
    longestEffectiveRange: &manualLinkRange
    inRange:editorRange
  ];
  NSString *automaticUrl = [_editor->textView.textStorage
    attribute:AutomaticLinkAttributeName
    atIndex:searchLocation
    longestEffectiveRange: &automaticLinkRange
    inRange:editorRange
  ];
  
  if((manualUrl == nullptr && automaticUrl == nullptr) || (manualLinkRange.length == 0 && automaticLinkRange.length == 0)) {
    return nullptr;
  }
  
  NSString *linkUrl = manualUrl == nullptr ? automaticUrl : manualUrl;
  NSRange linkRange = manualUrl == nullptr ? automaticLinkRange : manualLinkRange;
  
  LinkData *data = [[LinkData alloc] init];
  data.url = linkUrl;
  data.text = [_editor->textView.textStorage.string substringWithRange:linkRange];
  return data;
}

// returns full range of a link at some location
- (NSRange)getFullLinkRangeAt:(NSUInteger)location {
  NSRange manualLinkRange = NSMakeRange(0, 0);
  NSRange automaticLinkRange = NSMakeRange(0, 0);
  NSRange editorRange = NSMakeRange(0, _editor->textView.textStorage.length);
  
  // get the previous index if possible when at the very end of input
  NSUInteger searchLocation = location;
  if(searchLocation == _editor->textView.textStorage.length) {
    if(searchLocation == 0) {
      return NSMakeRange(0, 0);
    } else {
      searchLocation = searchLocation - 1;
    }
  }
  
  [_editor->textView.textStorage
    attribute:ManualLinkAttributeName
    atIndex:searchLocation
    longestEffectiveRange: &manualLinkRange
    inRange:editorRange
  ];
  [_editor->textView.textStorage
    attribute:AutomaticLinkAttributeName
    atIndex:searchLocation
    longestEffectiveRange: &automaticLinkRange
    inRange:editorRange
  ];
  
  return manualLinkRange.length == 0 ? automaticLinkRange : manualLinkRange;
}

- (void)manageLinkTypingAttributes {
  // link's typing attribtues need to be removed at ALL times whenever we have some link around
  BOOL removeAttrs = NO;
  
  if(_editor->textView.selectedRange.length == 0) {
    // check before
    if(_editor->textView.selectedRange.location >= 1) {
      if([self detectStyle:NSMakeRange(_editor->textView.selectedRange.location - 1, 1)]) {
        removeAttrs = YES;
      }
    }
    // check after
    if(_editor->textView.selectedRange.location < _editor->textView.textStorage.length) {
      if([self detectStyle:NSMakeRange(_editor->textView.selectedRange.location, 1)]) {
        removeAttrs = YES;
      }
    }
  } else {
    if([self anyOccurence:_editor->textView.selectedRange]) {
      removeAttrs = YES;
    }
  }
  
  if(removeAttrs) {
    NSMutableDictionary *newTypingAttrs = [_editor->textView.typingAttributes mutableCopy];
    newTypingAttrs[NSForegroundColorAttributeName] = [_editor->config primaryColor];
    newTypingAttrs[NSUnderlineColorAttributeName] = [_editor->config primaryColor];
    if([_editor->config linkDecorationLine] == DecorationUnderline) {
      [newTypingAttrs removeObjectForKey:NSUnderlineStyleAttributeName];
    }
    _editor->textView.typingAttributes = newTypingAttrs;
  }
}

// handles detecting and removing automatic links
- (void)handleAutomaticLinks:(NSString *)word inRange:(NSRange)wordRange {
  InlineCodeStyle *inlineCodeStyle = [_editor->stylesDict objectForKey:@([InlineCodeStyle getStyleType])];
  MentionStyle *mentionStyle = [_editor->stylesDict objectForKey:@([MentionStyle getStyleType])];
  
  if (inlineCodeStyle == nullptr || mentionStyle == nullptr) {
    return;
  }
  
  // we don't recognize links along mentions
  if ([mentionStyle anyOccurence:wordRange]) {
    return;
  }
  
  // we don't recognize links among inline code
  if ([inlineCodeStyle anyOccurence:wordRange]) {
    return;
  }
  
  // remove connected different links
  [self removeConnectedLinksIfNeeded:word range:wordRange];
  
  // we don't recognize automatic links along manual ones
  __block BOOL manualLinkPresent = NO;
  [_editor->textView.textStorage enumerateAttribute:ManualLinkAttributeName inRange:wordRange options:0
    usingBlock:^(id value, NSRange range, BOOL *stop) {
      NSString *urlValue = (NSString *)value;
      if(urlValue != nullptr) {
        manualLinkPresent = YES;
        *stop = YES;
      }
  }];
  if(manualLinkPresent) {
    return;
  }
  
  NSRegularExpression *fullRegex = [NSRegularExpression regularExpressionWithPattern:@"http(s)?:\\/\\/www\\.[-a-zA-Z0-9@:%._\\+~#=]{1,256}\\.[a-z]{2,6}\\b([-a-zA-Z0-9@:%_\\+.~#?&//=]*)"
      options:0
      error:nullptr
  ];
  NSRegularExpression *wwwRegex = [NSRegularExpression regularExpressionWithPattern:@"www\\.[-a-zA-Z0-9@:%._\\+~#=]{1,256}\\.[a-z]{2,6}\\b([-a-zA-Z0-9@:%_\\+.~#?&//=]*)"
      options:0
      error:nullptr
  ];
  NSRegularExpression *bareRegex = [NSRegularExpression regularExpressionWithPattern:@"[-a-zA-Z0-9@:%._\\+~#=]{1,256}\\.[a-z]{2,6}\\b([-a-zA-Z0-9@:%_\\+.~#?&//=]*)"
      options:0
      error:nullptr
  ];
  
  NSString *regexPassedUrl = nullptr;
  
  if ([fullRegex numberOfMatchesInString:word options:0 range:NSMakeRange(0, word.length)]) {
    regexPassedUrl = word;
  } else if ([wwwRegex numberOfMatchesInString:word options:0 range:NSMakeRange(0, word.length)]) {
    regexPassedUrl = word;
  } else if ([bareRegex numberOfMatchesInString:word options:0 range:NSMakeRange(0, word.length)]) {
    regexPassedUrl = word;
  } else if ([self anyOccurence:wordRange]) {
    // there was some automatic link (because anyOccurence is true and we are sure there are no manual links)
    // still, it didn't pass any regex - needs to be removed
    [self removeAttributes:wordRange];
  }
  
  if(regexPassedUrl != nullptr) {
    // add style only if needed
    BOOL addStyle = YES;
    if([self detectStyle:wordRange]) {
      LinkData *currentData = [self getLinkDataAt:wordRange.location];
      if(currentData != nullptr && currentData.url != nullptr && [currentData.url isEqualToString:regexPassedUrl]) {
        addStyle = NO;
      }
    }
    if(addStyle) {
      [self addLink:word url:regexPassedUrl range:wordRange manual:NO];
    }
  
    // emit onLinkDetected
    [_editor emitOnLinkDetectedEvent:word url:regexPassedUrl];
  }
}

// handles refreshing manual links
- (void)handleManualLinks:(NSString *)word inRange:(NSRange)wordRange {
  // look for manual links within the word
  __block NSString *manualLinkMinValue = @"";
  __block NSString *manualLinkMaxValue = @"";
  __block NSInteger manualLinkMinIdx = -1;
  __block NSInteger manualLinkMaxIdx = -1;
  
  [_editor->textView.textStorage enumerateAttribute:ManualLinkAttributeName inRange:wordRange options:0
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
  if(manualLinkMinIdx == -1 || manualLinkMaxIdx == -1) {
    return;
  }
    
  // heuristic for refreshing manual links:
  // we update the Manual attribute between the bounds of existing ones
  // we do that only if the bounds point to the same url
  // this way manual link gets "extended" only if some characters were added inside it
  if([manualLinkMinValue isEqualToString:manualLinkMaxValue]) {
    NSRange newRange = NSMakeRange(manualLinkMinIdx, manualLinkMaxIdx - manualLinkMinIdx + 1);
    [_editor->textView.textStorage addAttribute:NSForegroundColorAttributeName value:[_editor->config linkColor] range:newRange];
    [_editor->textView.textStorage addAttribute:NSUnderlineColorAttributeName value:[_editor->config linkColor] range:newRange];
    if([_editor->config linkDecorationLine] == DecorationUnderline) {
      [_editor->textView.textStorage addAttribute:NSUnderlineStyleAttributeName value:@(NSUnderlineStyleSingle) range:newRange];
    }
    [_editor->textView.textStorage addAttribute:ManualLinkAttributeName value:manualLinkMinValue range:newRange];
  }
    
  // link typing attributes need to be fixed after these changes
  [self manageLinkTypingAttributes];
}

// MARK: - Private non-standard methods

// determines whether a given range contains only links pointing to one url
// assumes the whole range is links only already
- (BOOL)isSingleLinkIn:(NSRange)range {
  return [self findAllOccurences:range].count == 1;
}

- (void)removeConnectedLinksIfNeeded:(NSString *)word range:(NSRange)wordRange {
  BOOL anyAutomatic = [OccurenceUtils any:AutomaticLinkAttributeName withEditor:_editor inRange:wordRange
    withCondition: ^BOOL(id  _Nullable value, NSRange range) {
      return [self styleCondition:value :range];
    }
  ];
  BOOL anyManual = [OccurenceUtils any:ManualLinkAttributeName withEditor:_editor inRange:wordRange
    withCondition: ^BOOL(id  _Nullable value, NSRange range) {
      return [self styleCondition:value :range];
    }
  ];
  
  // both manual and automatic links are somewhere - delete!
  if(anyAutomatic && anyManual) {
    [self removeAttributes:wordRange];
    [self manageLinkTypingAttributes];
  }
  
  // we are now sure there is only one type of link there - and make sure it covers the whole word
  BOOL onlyLinks = [OccurenceUtils detectMultiple:@[ManualLinkAttributeName, AutomaticLinkAttributeName] withEditor:_editor inRange:wordRange
    withCondition: ^BOOL(id  _Nullable value, NSRange range) {
      return [self styleCondition:value :range];
    }
  ];
    
  // only one link might be present!
  if(onlyLinks && ![self isSingleLinkIn:wordRange]) {
    [self removeAttributes:wordRange];
    [self manageLinkTypingAttributes];
  }
}

@end
