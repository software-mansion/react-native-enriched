#import "StyleHeaders.h"
#import "ReactNativeRichTextEditorView.h"
#import "OccurenceUtils.h"
#import "TextInsertionUtils.h"
#import "UIView+React.h"

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
    [_editor->textView.textStorage removeAttribute:NSLinkAttributeName range:linkRange];
    [_editor->textView.textStorage removeAttribute:ManualLinkAttributeName range:linkRange];
    [_editor->textView.textStorage removeAttribute:AutomaticLinkAttributeName range:linkRange];
  }
  [_editor->textView.textStorage endEditing];
  // remove typing attributes as well
  NSMutableDictionary *newTypingAttrs = [_editor->textView.typingAttributes mutableCopy];
  [newTypingAttrs removeObjectForKey:NSLinkAttributeName];
  // no need to remove ManualLink or AutomaticLink since they don't work with typingAttributes
  _editor->textView.typingAttributes = newTypingAttrs;
}

// used for conflicts, we have to remove the whole link
- (void)removeTypingAttributes {
  NSRange linkRange = [self getFullLinkRangeAt:_editor->textView.selectedRange.location];
  [_editor->textView.textStorage beginEditing];
  [_editor->textView.textStorage removeAttribute:NSLinkAttributeName range:linkRange];
  [_editor->textView.textStorage removeAttribute:ManualLinkAttributeName range:linkRange];
  [_editor->textView.textStorage removeAttribute:AutomaticLinkAttributeName range:linkRange];
  [_editor->textView.textStorage endEditing];
  // remove typing attributes as well
  NSMutableDictionary *newTypingAttrs = [_editor->textView.typingAttributes mutableCopy];
  [newTypingAttrs removeObjectForKey:NSLinkAttributeName];
  // no need to remove ManualLink or AutomaticLink since they don't work with typingAttributess
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
    NSString *linkAttr = (NSString *)_editor->textView.typingAttributes[NSLinkAttributeName];
    if(linkAttr == nullptr) {
      return NO;
    }
    
    // we must make sure that the present link isn't mention but either a Manual or an Automatic link
    NSRange manualLinkRange = NSMakeRange(0, 0);
    NSRange automaticLinkRange = NSMakeRange(0, 0);
    NSRange editorRange = NSMakeRange(0, _editor->textView.textStorage.length);
  
    // get the previous index if possible when at the very end of input
    NSUInteger searchLocation = range.location;
    if(searchLocation == _editor->textView.textStorage.length) {
      if(searchLocation == 0) {
        return NO;
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
     attribute:ManualLinkAttributeName
     atIndex:searchLocation
     longestEffectiveRange: &automaticLinkRange
     inRange:editorRange
    ];
    
    return manualLinkRange.length != 0 || automaticLinkRange.length != 0;
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
  newAttrs[NSLinkAttributeName] = [url copy];
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
}

// used for getting exact link data at the given range
- (LinkData *)getCurrentLinkDataIn:(NSRange)range {
  NSRange linkRange = NSMakeRange(0, 0);
  NSRange editorRange = NSMakeRange(0, _editor->textView.textStorage.length);
  
  // get the previous index if possible when at the very end of input
  NSUInteger searchLocation = range.location;
  if(searchLocation == _editor->textView.textStorage.length) {
    if(searchLocation == 0) {
      return nullptr;
    } else {
      searchLocation = searchLocation - 1;
    }
  }
  
  NSString *url = [_editor->textView.textStorage
   attribute:NSLinkAttributeName
   atIndex:searchLocation
   longestEffectiveRange: &linkRange
   inRange:editorRange
  ];
  
  if(url == nullptr || linkRange.length == 0) {
    return nullptr;
  }
  
  LinkData *data = [[LinkData alloc] init];
  data.url = url;
  data.text = [_editor->textView.textStorage.string substringWithRange:linkRange];
  return data;
}

// returns full range of a link at some location, useful for removing links
// it assumes we have a link here (not a mention)
- (NSRange)getFullLinkRangeAt:(NSUInteger)location {
  NSRange linkRange = NSMakeRange(0, 0);
  NSRange editorRange = NSMakeRange(0, _editor->textView.textStorage.length);
  
  // get the previous index if possible when at the very end of input
  NSUInteger searchLocation = location;
  if(searchLocation == _editor->textView.textStorage.length) {
    if(searchLocation == 0) {
      return linkRange;
    } else {
      searchLocation = searchLocation - 1;
    }
  }
  
  [_editor->textView.textStorage
   attribute:NSLinkAttributeName
   atIndex:searchLocation
   longestEffectiveRange: &linkRange
   inRange:editorRange
  ];
  return linkRange;
}

- (void)manageLinkTypingAttributes {
  // manual link can be extended via typing attributes only if it's done from the inside
  // adding text before or after shouldn't be considered a link
  // that's why we remove typing attributes in these cases here
  if(_editor->textView.selectedRange.length > 0) {
    return;
  }
  
  BOOL linkBefore = NO;
  if(_editor->textView.selectedRange.location >= 1) {
    NSRange rangeBefore = NSMakeRange(_editor->textView.selectedRange.location - 1, 1);
    if([self anyOccurence:rangeBefore]) {
      linkBefore = YES;
    }
  }
  
  if(!linkBefore) {
    NSMutableDictionary *newTypingAttrs = [_editor->textView.typingAttributes mutableCopy];
    [newTypingAttrs removeObjectForKey:NSLinkAttributeName];
    _editor->textView.typingAttributes = newTypingAttrs;
    return;
  }
  
  BOOL linkAfter = NO;
  if(_editor->textView.selectedRange.location < _editor->textView.textStorage.length) {
    NSRange rangeAfter = NSMakeRange(_editor->textView.selectedRange.location, 1);
    if([self anyOccurence:rangeAfter]) {
      linkAfter = YES;
    }
  }
  
  if(!linkAfter) {
    NSMutableDictionary *newTypingAttrs = [_editor->textView.typingAttributes mutableCopy];
    [newTypingAttrs removeObjectForKey:NSLinkAttributeName];
    _editor->textView.typingAttributes = newTypingAttrs;
  }
}

// handles automatic links and extending the custom NSAttributedKeys
- (void)handleAutomaticLinks:(NSString *)word inRange:(NSRange)wordRange {
  InlineCodeStyle *inlineCodeStyle = [_editor->stylesDict objectForKey:@([InlineCodeStyle getStyleType])];
  //MentionStyle *mentionStyle = [[_editor->stylesDict objectForKey:@([MentionStyle getStyleType])];
  
  if (inlineCodeStyle == nullptr /*|| mentionStyle == nullptr*/) {
    return;
  }
  
//  // we don't recognize links along mentions
//  if ([mentionStyle anyOccurence:wordRange) {
//    return;
//  }
  
  // we don't recognize links among inline code
  if ([inlineCodeStyle anyOccurence:wordRange]) {
    return;
  }
  
  // remove connected different links
  if(![self isSingleLinkIn:wordRange]) {
    [self removeAttributes:wordRange];
    return;
  }
  
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
  
  BOOL manualLinkPresent = manualLinkMinIdx != -1 && manualLinkMaxIdx != -1;
  if (manualLinkPresent) {
    // this is a heuristic for refreshing manual links:
    // since manual links cannot be extended from the sides, but can be from the inside,
    // we update the attribute between the bounds of the already existing one
    // we do that only if the bounds are the same one link though
    if ([manualLinkMinValue isEqualToString:manualLinkMaxValue]) {
      NSRange newManualAttributeRange = NSMakeRange(manualLinkMinIdx, manualLinkMaxIdx - manualLinkMinIdx + 1);
      [_editor->textView.textStorage addAttribute:ManualLinkAttributeName value:manualLinkMinValue range:newManualAttributeRange];
    }
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
    [self addLink:word url:word range:wordRange manual:NO];
    regexPassedUrl = word;
  } else if ([wwwRegex numberOfMatchesInString:word options:0 range:NSMakeRange(0, word.length)]) {
    NSString *httpWord = [NSString stringWithFormat:@"https://%@", word];
    [self addLink:word url:httpWord range:wordRange manual:NO];
    regexPassedUrl = httpWord;
  } else if ([bareRegex numberOfMatchesInString:word options:0 range:NSMakeRange(0, word.length)]) {
    NSString *httpWwwWord = [NSString stringWithFormat:@"https://www.%@", word];
    [self addLink:word url:httpWwwWord range:wordRange manual:NO];
    regexPassedUrl = httpWwwWord;
  } else if ([self anyOccurence:wordRange]) {
    // there was some automatic link (because anyOccurence is true and we are sure there are no manual links)
    // still, it didn't pass any regex - needs to be removed
    [self removeAttributes:wordRange];
  }
  
  if(regexPassedUrl != nullptr) {
    // emit onLinkDetected
    [_editor emitOnLinkDetectedEvent:word url:regexPassedUrl];
    
    // fix typing attributes if we made automatic link while being inside of its detection range
    NSRange editorRange = _editor->textView.selectedRange;
    if(editorRange.length == 0 &&
       editorRange.location > wordRange.location &&
       editorRange.location < wordRange.location + wordRange.length
    ) {
      NSMutableDictionary *newTypingAttrs = [_editor->textView.typingAttributes mutableCopy];
      newTypingAttrs[NSLinkAttributeName] = regexPassedUrl;
      _editor->textView.typingAttributes = newTypingAttrs;
    }
  }
}

// MARK: - Private non-standard methods

// determines whether a given range contains only links pointing to one url
// assumes the whole range is links only already
- (BOOL)isSingleLinkIn:(NSRange)range {
  __block NSString *linkUrl;
  __block BOOL isSigleLink = YES;
  // we can enumerate NSLinkAttributeName since it should have same values as Manual and Automatic links
  [_editor->textView.textStorage enumerateAttribute:NSLinkAttributeName inRange:range options:0 usingBlock:
     ^(id  _Nullable value, NSRange range, BOOL * _Nonnull stop) {
    NSString *linkValue = (NSString *)value;
    if(linkValue != nullptr && linkUrl == nullptr) {
      linkUrl = linkValue;
    } else if(linkValue != nullptr && linkValue != linkUrl) {
      isSigleLink = NO;
      *stop = YES;
    }
  }
  ];
  return isSigleLink;
}

@end
