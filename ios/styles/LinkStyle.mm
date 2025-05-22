#import "StyleHeaders.h"
#import "ReactNativeRichTextEditorView.h"
#import "OccurenceUtils.h"
#import "TextInsertionUtils.h"
#import "UIView+React.h"

// custom NSAttributedStringKey to differentiate manually added and automatically detected links
static NSString *const ManualLinkAttributeName = @"ManualLinkAttributeName";

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
  }
  [_editor->textView.textStorage endEditing];
}

// used for conflicts or removeLink ref method, we have to remove the whole link
- (void)removeTypingAttributes {
  NSRange linkRange = [self getFullLinkRangeAt:_editor->currentSelection.location];
  [_editor->textView.textStorage beginEditing];
  [_editor->textView.textStorage removeAttribute:NSLinkAttributeName range:linkRange];
  [_editor->textView.textStorage removeAttribute:ManualLinkAttributeName range:linkRange];
  [_editor->textView.textStorage endEditing];
}

- (BOOL)styleCondition:(id _Nullable)value :(NSRange)range {
  NSString *linkValue = (NSString *)value;
  return linkValue != nullptr;
}

- (BOOL)detectStyle:(NSRange)range {
  if(range.length >= 1) {
    BOOL onlyLinks = [OccurenceUtils detect:NSLinkAttributeName withEditor:_editor inRange:range
      withCondition: ^BOOL(id  _Nullable value, NSRange range) {
        return [self styleCondition:value :range];
      }
    ];
    return onlyLinks ? [self isSingleLinkIn:range] : NO;
  } else {
    NSString *linkAttr = (NSString *)_editor->textView.typingAttributes[NSLinkAttributeName];
    return linkAttr != nullptr;
  }
}

- (BOOL)anyOccurence:(NSRange)range {
  return [OccurenceUtils any:NSLinkAttributeName withEditor:_editor inRange:range
    withCondition:^BOOL(id  _Nullable value, NSRange range) {
      return [self styleCondition:value :range];
    }
  ];
}

- (NSArray<StylePair *> *_Nullable)findAllOccurences:(NSRange)range {
  return [OccurenceUtils all:NSLinkAttributeName withEditor:_editor inRange:range
    withCondition:^BOOL(id  _Nullable value, NSRange range) {
      return [self styleCondition:value :range];
    }
  ];
}

// MARK: - Public non-standard methods

- (void)addLink:(NSString*)text url:(NSString*)url manual:(BOOL)manual {
  NSString *currentText = [_editor->textView.text substringWithRange:_editor->currentSelection];
  
  NSMutableDictionary<NSAttributedStringKey, id> *newAttrs = [[NSMutableDictionary<NSAttributedStringKey, id> alloc] init];
  newAttrs[NSLinkAttributeName] = url;
  if(manual) {
    // manual link has some mock value
    newAttrs[ManualLinkAttributeName] = @(YES);
  }
  
  if(_editor->currentSelection.length == 0) {
    // insert link
    [TextInsertionUtils insertText:text inView:_editor->textView at:_editor->currentSelection.location additionalAttributes:newAttrs];
  } else if([currentText isEqualToString:text]) {
    // apply link attributes and change selection
    [_editor->textView.textStorage addAttributes:newAttrs range:_editor->currentSelection];
  } else {
    // replace text with link
    [TextInsertionUtils replaceText:text inView:_editor->textView at:_editor->currentSelection additionalAttributes:newAttrs];
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
  data.text = [_editor->textView.text substringWithRange:linkRange];
  return data;
}

// returns full range of a link at some location, useful for removing links
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
  if(_editor->currentSelection.length > 0) {
    return;
  }

  __block BOOL linkBefore = NO;
  if(_editor->currentSelection.location >= 1) {
    NSRange rangeBefore = NSMakeRange(_editor->currentSelection.location - 1, 1);
    [_editor->textView.textStorage enumerateAttribute:NSLinkAttributeName inRange:rangeBefore options:0
      usingBlock:^(id  _Nullable value, NSRange range, BOOL * _Nonnull stop) {
        NSString *linkValue = (NSString *)value;
        if(linkValue != nullptr) {
          linkBefore = YES;
          *stop = YES;
        }
      }
    ];
  }

  if(!linkBefore) {
      NSMutableDictionary *newTypingAttrs = [_editor->textView.typingAttributes mutableCopy];
      [newTypingAttrs removeObjectForKey:NSLinkAttributeName];
      _editor->textView.typingAttributes = newTypingAttrs;
      return;
  }

  __block BOOL linkAfter = NO;
  if(_editor->currentSelection.location < _editor->textView.textStorage.length) {
    NSRange rangeAfter = NSMakeRange(_editor->currentSelection.location, 1);
    [_editor->textView.textStorage enumerateAttribute:NSLinkAttributeName inRange:rangeAfter options:0
      usingBlock:^(id  _Nullable value, NSRange range, BOOL * _Nonnull stop) {
        NSString *linkValue = (NSString *)value;
        if(linkValue != nullptr) {
          linkAfter = YES;
          *stop = YES;
        }
      }
    ];
  }

  if(!linkAfter) {
      NSMutableDictionary *newTypingAttrs = [_editor->textView.typingAttributes mutableCopy];
      [newTypingAttrs removeObjectForKey:NSLinkAttributeName];
      _editor->textView.typingAttributes = newTypingAttrs;
  }
}

// MARK: - Private non-standard methods

// determines whether a given range contains only links pointing to one url
- (BOOL)isSingleLinkIn:(NSRange)range {
  __block NSString *linkUrl;
  __block BOOL isSigleLink = YES;
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
