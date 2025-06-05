#import "StyleHeaders.h"
#import "ReactNativeRichTextEditorView.h"
#import "OccurenceUtils.h"
#import "TextInsertionUtils.h"
#import "WordsUtils.h"
#import "UIView+React.h"

// custom NSAttributedStringKey to differentiate from links
static NSString *const MentionAttributeName = @"MentionAttributeName";

@implementation MentionStyle {
  ReactNativeRichTextEditorView *_editor;
  NSValue *_activeMentionRange;
  NSString *_activeMentionIndicator;
  BOOL _blockMentionEditing;
}

+ (StyleType)getStyleType { return Mention; }

- (instancetype)initWithEditor:(id)editor {
  self = [super init];
  _editor = (ReactNativeRichTextEditorView *) editor;
  _activeMentionRange = nullptr;
  _activeMentionIndicator = nullptr;
  _blockMentionEditing = NO;
  return self;
}

- (void)applyStyle:(NSRange)range {
  // no-op for mentions
}

- (void)addAttributes:(NSRange)range {
  // no-op for mentions
}

- (void)addTypingAttributes {
  // no-op for mentions
}

// we have to make sure all mentions get removed properly
- (void)removeAttributes:(NSRange)range {
  NSArray<StylePair *> *mentions = [self findAllOccurences:range];
  [_editor->textView.textStorage beginEditing];
  for(StylePair *pair in mentions) {
    NSRange mentionRange = [self getFullMentionRangeAt:[pair.rangeValue rangeValue].location];
    [_editor->textView.textStorage removeAttribute:MentionAttributeName range:mentionRange];
    [_editor->textView.textStorage addAttribute:NSForegroundColorAttributeName value:[_editor->config primaryColor] range:mentionRange];
    [_editor->textView.textStorage addAttribute:NSUnderlineColorAttributeName value:[_editor->config primaryColor] range:mentionRange];
    [_editor->textView.textStorage removeAttribute:NSBackgroundColorAttributeName range:mentionRange];
  }
  [_editor->textView.textStorage endEditing];
  
  // remove typing attributes as well
  NSMutableDictionary *newTypingAttrs = [_editor->textView.typingAttributes mutableCopy];
  newTypingAttrs[NSForegroundColorAttributeName] = [_editor->config primaryColor];
  newTypingAttrs[NSUnderlineColorAttributeName] = [_editor->config primaryColor];
  [newTypingAttrs removeObjectForKey:NSBackgroundColorAttributeName];
  _editor->textView.typingAttributes = newTypingAttrs;
}

// used for conflicts, we have to remove the whole mention
- (void)removeTypingAttributes {
  NSRange mentionRange = [self getFullMentionRangeAt:_editor->textView.selectedRange.location];
  [_editor->textView.textStorage beginEditing];
  [_editor->textView.textStorage removeAttribute:MentionAttributeName range:mentionRange];
  [_editor->textView.textStorage addAttribute:NSForegroundColorAttributeName value:[_editor->config primaryColor] range:mentionRange];
  [_editor->textView.textStorage addAttribute:NSUnderlineColorAttributeName value:[_editor->config primaryColor] range:mentionRange];
  [_editor->textView.textStorage removeAttribute:NSBackgroundColorAttributeName range:mentionRange];
  [_editor->textView.textStorage endEditing];
  
  // remove typing attributes as well
  NSMutableDictionary *newTypingAttrs = [_editor->textView.typingAttributes mutableCopy];
  newTypingAttrs[NSForegroundColorAttributeName] = [_editor->config primaryColor];
  newTypingAttrs[NSUnderlineColorAttributeName] = [_editor->config primaryColor];
  [newTypingAttrs removeObjectForKey:NSBackgroundColorAttributeName];
  _editor->textView.typingAttributes = newTypingAttrs;
}

- (BOOL)styleCondition:(id _Nullable)value :(NSRange)range {
  MentionParams *params = (MentionParams *)value;
  return params != nullptr;
}

- (BOOL)detectStyle:(NSRange)range {
  if(range.length >= 1) {
    return [OccurenceUtils detect:MentionAttributeName withEditor:_editor inRange:range
      withCondition: ^BOOL(id  _Nullable value, NSRange range) {
        return [self styleCondition:value :range];
      }
    ];
  } else {
    return [self getMentionParamsAt:range.location] != nullptr;
  }
}

- (BOOL)anyOccurence:(NSRange)range {
  return [OccurenceUtils any:MentionAttributeName withEditor:_editor inRange:range
    withCondition:^BOOL(id  _Nullable value, NSRange range) {
      return [self styleCondition:value :range];
    }
  ];
}

- (NSArray<StylePair *> *_Nullable)findAllOccurences:(NSRange)range {
  return [OccurenceUtils all:MentionAttributeName withEditor:_editor inRange:range
    withCondition:^BOOL(id  _Nullable value, NSRange range) {
      return [self styleCondition:value :range];
    }
  ];
}

// MARK: - Public non-standard methods

- (void)addMention:(NSString *)indicator text:(NSString *)text attributes:(NSString *)attributes {
  if(_activeMentionRange == nullptr) {
    return;
  }
  
  // we block callbacks resulting from manageMentionEditing while we tamper with them here
  _blockMentionEditing = YES;
  
  MentionParams *params = [[MentionParams alloc] init];
  params.text = text;
  params.attributes = attributes;
  NSDictionary<NSAttributedStringKey, id> *newAttrs = @{
    MentionAttributeName: params,
    NSBackgroundColorAttributeName: [[UIColor systemBlueColor] colorWithAlphaComponent:0.6], // TODO: mentions style config
    NSForegroundColorAttributeName: [UIColor systemBlueColor] // TODO: mentions style config
  };
  
  // add a single space after the mention
  NSString *newText = [NSString stringWithFormat:@"%@ ", text];
  NSRange rangeToBeReplaced = [_activeMentionRange rangeValue];
  [TextInsertionUtils replaceText:newText inView: _editor->textView at:rangeToBeReplaced additionalAttributes:nullptr];
  
  // THEN, add the attributes to not apply them on the space
  [_editor->textView.textStorage addAttributes:newAttrs range:NSMakeRange(rangeToBeReplaced.location, text.length)];
  
  // mention editing should finish
  [self removeActiveMentionRange];
  
  // unlock editing
  _blockMentionEditing = NO;
}

- (void)startMentionWithIndicator:(NSString *)indicator {
  NSRange currentRange = _editor->textView.selectedRange;
  
  BOOL addSpaceBefore = NO;
  BOOL addSpaceAfter = NO;
  
  if(currentRange.location > 0) {
    unichar charBefore = [_editor->textView.textStorage.string characterAtIndex:(currentRange.location - 1)];
    if(![[NSCharacterSet whitespaceAndNewlineCharacterSet] characterIsMember:charBefore]) {
      addSpaceBefore = YES;
    }
  }
  
  if(currentRange.location + currentRange.length < _editor->textView.textStorage.string.length) {
    unichar charAfter = [_editor->textView.textStorage.string characterAtIndex:(currentRange.location + currentRange.length)];
    if(![[NSCharacterSet whitespaceAndNewlineCharacterSet] characterIsMember:charAfter]) {
      addSpaceAfter = YES;
    }
  }
  
  NSString *finalString = [NSString stringWithFormat:@"%@%@%@",
    addSpaceBefore ? @" " : @"",
    indicator,
    addSpaceAfter ? @" " : @""
  ];
  
  NSRange newSelect = NSMakeRange(currentRange.location + finalString.length + (addSpaceAfter ? -1 : 0), 0);
  
  if(currentRange.length == 0) {
    [TextInsertionUtils insertText:finalString inView:_editor->textView at:currentRange.location additionalAttributes:nullptr];
  } else {
    [TextInsertionUtils replaceText:finalString inView:_editor->textView at:currentRange additionalAttributes:nullptr];
  }
  
  [_editor->textView reactFocus];
  _editor->textView.selectedRange = newSelect;
}

// handles removing no longer valid mentions
- (void)handleExistingMentions {
  // unfortunately whole text needs to be checked for them
  // checking the modified words doesn't work because mention's text can have any number of spaces, which makes one mention any number of words long
  
  NSRange wholeText = NSMakeRange(0, _editor->textView.textStorage.string.length);
  // get menntions in ascending range.location order
  NSArray<StylePair *> *mentions = [[self findAllOccurences:wholeText] sortedArrayUsingComparator:^NSComparisonResult(id  _Nonnull obj1, id  _Nonnull obj2) {
    NSRange range1 = [((StylePair *)obj1).rangeValue rangeValue];
    NSRange range2 = [((StylePair *)obj2).rangeValue rangeValue];
    if(range1.location < range2.location) {
      return NSOrderedAscending;
    } else {
      return NSOrderedDescending;
    }
  }];
  
  // set of ranges to have their mentions removed - aren't valid anymore
  NSMutableSet<NSValue *> *rangesToRemove = [[NSMutableSet alloc] init];
  
  for(NSInteger i = 0; i < mentions.count; i++) {
    StylePair *mention = mentions[i];
    NSRange currentRange = [mention.rangeValue rangeValue];
    NSString *currentText = ((MentionParams *)mention.styleValue).text;
    // check locations with the previous mention if it exists - if they got merged they need to be removed
    if(i > 0) {
      NSRange prevRange = [((StylePair*)mentions[i-1]).rangeValue rangeValue];
      // mentions merged - both need to go out
      if(prevRange.location + prevRange.length == currentRange.location) {
        [rangesToRemove addObject:[NSValue valueWithRange:prevRange]];
        [rangesToRemove addObject:[NSValue valueWithRange:currentRange]];
        continue;
      }
    }
    
    // check for text, any modifications to it makes mention invalid
    NSString *existingText = [_editor->textView.textStorage.string substringWithRange:currentRange];
    if(![existingText isEqualToString:currentText]) {
      [rangesToRemove addObject:[NSValue valueWithRange:currentRange]];
    }
  }
  
  for(NSValue *value in rangesToRemove) {
    [self removeAttributes:[value rangeValue]];
  }
}

// manages active mention range, which in turn emits proper onMention event
- (void)manageMentionEditing {
  // no actions performed when block is active
  if(_blockMentionEditing) {
    return;
  }

  // we don't take longer selections into consideration
  if(_editor->textView.selectedRange.length > 0) {
    [self removeActiveMentionRange];
    return;
  }
  
  // get the current word if it exists
  // we can be using current word only thanks to the fact that ongoing mentions are always one word (in contrast to ready, added mentions)
  NSDictionary *currentWord = [WordsUtils getCurrentWord:_editor->textView.textStorage.string range:_editor->textView.selectedRange];
  if(currentWord == nullptr) {
    [self removeActiveMentionRange];
    return;
  }
  
  // get word properties
  NSString *wordText = (NSString *)[currentWord objectForKey:@"word"];
  NSValue *wordRangeValue = (NSValue *)[currentWord objectForKey:@"range"];
  if(wordText == nullptr || wordRangeValue == nullptr) {
    [self removeActiveMentionRange];
    return;
  }
  NSRange wordRange = [wordRangeValue rangeValue];
  
  // check for mentionIndicators - no sign of them means we shouldn't be editing a mention
  unichar firstChar = [wordText characterAtIndex:0];
  if(![[_editor->config mentionIndicators] containsObject: @(firstChar)]) {
    [self removeActiveMentionRange];
    return;
  }
  
  // check for existing mentions - we don't edit them
  if([self detectStyle:wordRange]) {
    [self removeActiveMentionRange];
    return;
  }
  
  // get conflicting style classes
  LinkStyle* linkStyle = [_editor->stylesDict objectForKey:@([LinkStyle getStyleType])];
  InlineCodeStyle* inlineCodeStyle = [_editor->stylesDict objectForKey:@([InlineCodeStyle getStyleType])];
  if(linkStyle == nullptr || inlineCodeStyle == nullptr) {
    [self removeActiveMentionRange];
    return;
  }
  
  // if there is any sign of conflicting style classes, stop editing a mention
  if([linkStyle anyOccurence:wordRange] || [inlineCodeStyle anyOccurence:wordRange]) {
    [self removeActiveMentionRange];
    return;
  }
  
  // everything checks out - we are indeed editing a mention
  [self setActiveMentionRange:wordRange text:wordText];
}

// used to fix mentions' typing attributes
- (void)manageMentionTypingAttributes {
  // same as with links, mentions' typing attributes need to be constantly removed whenever we are somewhere near
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
    [newTypingAttrs removeObjectForKey:NSBackgroundColorAttributeName];
    _editor->textView.typingAttributes = newTypingAttrs;
  }
}

// returns mention params if it exists
- (MentionParams *)getMentionParamsAt:(NSUInteger)location {
  NSRange mentionRange = NSMakeRange(0, 0);
  NSRange editorRange = NSMakeRange(0, _editor->textView.textStorage.length);
  
  // don't search at the very end of input
  NSUInteger searchLocation = location;
  if(searchLocation == _editor->textView.textStorage.length) {
    return nullptr;
  }
  
  MentionParams *value = [_editor->textView.textStorage
   attribute:MentionAttributeName
   atIndex:searchLocation
   longestEffectiveRange: &mentionRange
   inRange:editorRange
  ];
  return value;
}

- (NSValue *)getActiveMentionRange {
  return _activeMentionRange;
}

// returns full range of a mention at some location
- (NSRange)getFullMentionRangeAt:(NSUInteger)location {
  NSRange mentionRange = NSMakeRange(0, 0);
  NSRange editorRange = NSMakeRange(0, _editor->textView.textStorage.length);
  
  // get the previous index if possible when at the very end of input
  NSUInteger searchLocation = location;
  if(searchLocation == _editor->textView.textStorage.length) {
    if(searchLocation == 0) {
      return mentionRange;
    } else {
      searchLocation = searchLocation - 1;
    }
  }
  
  [_editor->textView.textStorage
   attribute:MentionAttributeName
   atIndex:searchLocation
   longestEffectiveRange: &mentionRange
   inRange:editorRange
  ];
  return mentionRange;
}

// MARK: - Private non-standard methods

// both used for setting the active mention range + indicator and fires proper onMention event
- (void)setActiveMentionRange:(NSRange)range text:(NSString *)text {
  NSString *indicatorString = [NSString stringWithFormat:@"%C", [text characterAtIndex:0]];
  NSString *textString = [text substringWithRange:NSMakeRange(1, text.length - 1)];
  _activeMentionIndicator = indicatorString;
  _activeMentionRange = [NSValue valueWithRange:range];
  [_editor emitOnMentionEvent:indicatorString text:textString];
}

// removes stored mention range + indicator, which means that we no longer edit a mention and onMention event gets fired
- (void)removeActiveMentionRange {
  if(_activeMentionIndicator != nullptr && _activeMentionRange != nullptr) {
    NSString *indicatorCopy = [_activeMentionIndicator copy];
    _activeMentionIndicator = nullptr;
    _activeMentionRange = nullptr;
    [_editor emitOnMentionEvent:indicatorCopy text:nullptr];
  }
}

@end

