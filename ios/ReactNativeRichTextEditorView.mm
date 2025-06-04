#import "ReactNativeRichTextEditorView.h"
#import "RCTFabricComponentsPlugins.h"
#import <ReactNativeRichTextEditor/ReactNativeRichTextEditorViewComponentDescriptor.h>
#import <ReactNativeRichTextEditor/EventEmitters.h>
#import <ReactNativeRichTextEditor/Props.h>
#import <ReactNativeRichTextEditor/RCTComponentViewHelpers.h>
#import <react/utils/ManagedObjectWrapper.h>
#import <folly/dynamic.h>
#import "UIView+React.h"
#import "StringExtension.h"
#import "CoreText/CoreText.h"
#import <React/RCTConversions.h>
#import "StyleHeaders.h"
#import "WordsUtils.h"

using namespace facebook::react;

@interface ReactNativeRichTextEditorView () <RCTReactNativeRichTextEditorViewViewProtocol, UITextViewDelegate, NSObject>

@end

@implementation ReactNativeRichTextEditorView {
  ReactNativeRichTextEditorViewShadowNode::ConcreteState::Shared _state;
  int _componentViewHeightUpdateCounter;
  NSMutableDictionary<NSAttributedStringKey, id> *_defaultTypingAttributes;
  NSMutableSet<NSNumber *> *_activeStyles;
  NSArray<NSDictionary *> *_modifiedWords;
  LinkData *_recentlyActiveLinkData;
  NSRange _recentlyActiveLinkRange;
  NSRange _recentlyChangedRange;
  NSString *_recentlyEmittedString;
  MentionParams *_recentlyActiveMentionParams;
  NSRange _recentlyActiveMentionRange;
}

// MARK: - Component utils

+ (ComponentDescriptorProvider)componentDescriptorProvider {
  return concreteComponentDescriptorProvider<ReactNativeRichTextEditorViewComponentDescriptor>();
}

Class<RCTComponentViewProtocol> ReactNativeRichTextEditorViewCls(void) {
  return ReactNativeRichTextEditorView.class;
}

+ (BOOL)shouldBeRecycled {
  return NO;
}

// MARK: - Init

- (instancetype)initWithFrame:(CGRect)frame {
  if (self = [super initWithFrame:frame]) {
    static const auto defaultProps = std::make_shared<const ReactNativeRichTextEditorViewProps>();
    _props = defaultProps;
    [self setDefaults];
    [self setupTextView];
    self.contentView = textView;
  }
  return self;
}

- (void)setDefaults {
  _componentViewHeightUpdateCounter = 0;
  _activeStyles = [[NSMutableSet alloc] init];
  _recentlyActiveLinkRange = NSMakeRange(0, 0);
  _recentlyActiveMentionRange = NSMakeRange(0, 0);
  _recentlyChangedRange = NSMakeRange(0, 0);
  _recentlyEmittedString = @"";
  
  stylesDict = @{
    @([BoldStyle getStyleType]) : [[BoldStyle alloc] initWithEditor:self],
    @([ItalicStyle getStyleType]): [[ItalicStyle alloc] initWithEditor:self],
    @([UnderlineStyle getStyleType]): [[UnderlineStyle alloc] initWithEditor:self],
    @([StrikethroughStyle getStyleType]): [[StrikethroughStyle alloc] initWithEditor:self],
    @([InlineCodeStyle getStyleType]): [[InlineCodeStyle alloc] initWithEditor:self],
    @([LinkStyle getStyleType]): [[LinkStyle alloc] initWithEditor:self],
    @([MentionStyle getStyleType]): [[MentionStyle alloc] initWithEditor:self]
  };
  
  conflictingStyles = @{
    @([BoldStyle getStyleType]) : @[],
    @([ItalicStyle getStyleType]) : @[],
    @([UnderlineStyle getStyleType]) : @[],
    @([StrikethroughStyle getStyleType]) : @[],
    @([InlineCodeStyle getStyleType]) : @[@([LinkStyle getStyleType]), @([MentionStyle getStyleType])],
    @([LinkStyle getStyleType]): @[@([InlineCodeStyle getStyleType]), @([LinkStyle getStyleType]), @([MentionStyle getStyleType])],
    @([MentionStyle getStyleType]): @[@([InlineCodeStyle getStyleType]), @([LinkStyle getStyleType])]
  };
  
  blockingStyles = @{
    @([BoldStyle getStyleType]) : @[],
    @([ItalicStyle getStyleType]) : @[],
    @([UnderlineStyle getStyleType]) : @[],
    @([StrikethroughStyle getStyleType]) : @[],
    @([InlineCodeStyle getStyleType]) : @[],
    @([LinkStyle getStyleType]): @[],
    @([MentionStyle getStyleType]): @[],
  };
}

- (void)setupTextView {
  textView = [[UITextView alloc] init];
  textView.backgroundColor = UIColor.clearColor;
  textView.textContainerInset = UIEdgeInsetsMake(0, 0, 0, 0);
  textView.textContainer.lineFragmentPadding = 0;
  textView.delegate = self;
}

// MARK: - Props

- (void)updateProps:(Props::Shared const &)props oldProps:(Props::Shared const &)oldProps {
  const auto &oldViewProps = *std::static_pointer_cast<ReactNativeRichTextEditorViewProps const>(_props);
  const auto &newViewProps = *std::static_pointer_cast<ReactNativeRichTextEditorViewProps const>(props);
  BOOL heightUpdateNeeded = NO;
  BOOL isFirstMount = NO;
  
  // initial config
  // TODO: handle reacting to config props when styles are relatively working
  if(config == nullptr) {
    isFirstMount = YES;
    EditorConfig *newConfig = [[EditorConfig alloc] init];
  
    if(newViewProps.color) {
      UIColor *uiColor = RCTUIColorFromSharedColor(newViewProps.color);
      [newConfig setPrimaryColor:uiColor];
    }
    
    if(newViewProps.fontSize) {
      NSNumber* fontSize = @(newViewProps.fontSize);
      [newConfig setPrimaryFontSize: fontSize];
    }
    
    if(!newViewProps.fontWeight.empty()) {
      [newConfig setPrimaryFontWeight: [NSString fromCppString:newViewProps.fontWeight]];
    }
    
    if(!newViewProps.fontFamily.empty()) {
      [newConfig setPrimaryFontFamily: [NSString fromCppString:newViewProps.fontFamily]];
    }
    
    // set the config
    config = newConfig;
    // fill the typing attributes
    _defaultTypingAttributes = [[NSMutableDictionary<NSAttributedStringKey, id> alloc] init];
    _defaultTypingAttributes[NSForegroundColorAttributeName] = [newConfig primaryColor];
    _defaultTypingAttributes[NSFontAttributeName] = [newConfig primaryFont];
    _defaultTypingAttributes[NSUnderlineColorAttributeName] = [newConfig primaryColor];
    _defaultTypingAttributes[NSStrikethroughColorAttributeName] = [newConfig primaryColor];
    textView.typingAttributes = _defaultTypingAttributes;
  }
  
  // default value
  if(newViewProps.defaultValue != oldViewProps.defaultValue) {
    textView.text = [NSString fromCppString:newViewProps.defaultValue];
    heightUpdateNeeded = YES;
  }
  
  // mention indicators
  auto mismatchPair = std::mismatch(
    newViewProps.mentionIndicators.begin(), newViewProps.mentionIndicators.end(),
    oldViewProps.mentionIndicators.begin(), oldViewProps.mentionIndicators.end()
  );
  if(mismatchPair.first != newViewProps.mentionIndicators.end() || mismatchPair.second != oldViewProps.mentionIndicators.end()) {
    NSMutableSet<NSNumber *> *newIndicators = [[NSMutableSet alloc] init];
    for(const std::string &item : newViewProps.mentionIndicators) {
      if(item.length() == 1) {
        [newIndicators addObject:@(item[0])];
      }
    }
    [config setMentionIndicators:newIndicators];
  }
  
  [super updateProps:props oldProps:oldProps];
  
  if(heightUpdateNeeded) {
    [self tryUpdatingHeight];
  }
  
  // needs to be done at the very end
  if(isFirstMount && newViewProps.autoFocus) {
    [textView reactFocus];
  }
}

// MARK: - Measuring and states

- (CGSize)measureSize:(CGFloat)maxWidth {
  // copy the the whole attributed string
  NSMutableAttributedString *currentStr = [[NSMutableAttributedString alloc] initWithAttributedString:textView.textStorage];
  
  // edge case: empty input should still be of a height of a single line, so we add a mock "I" character
  if([currentStr length] == 0 ) {
    [currentStr appendAttributedString:
       [[NSAttributedString alloc] initWithString:@"I" attributes:_defaultTypingAttributes]
    ];
  }
  
  // edge case: trailing newlines aren't counted towards height calculations, so we add a mock "I" character
  if([currentStr length] > 0 && [[currentStr.string substringFromIndex:[currentStr length] - 1] isEqualToString:@"\n"]) {
    [currentStr appendAttributedString:
       [[NSAttributedString alloc] initWithString:@"I" attributes:_defaultTypingAttributes]
    ];
  }

  CTFramesetterRef framesetter = CTFramesetterCreateWithAttributedString((CFAttributedStringRef)currentStr);
  
  const CGSize &suggestedSize = CTFramesetterSuggestFrameSizeWithConstraints(
    framesetter,
    CFRangeMake(0, currentStr.length),
    nullptr,
    CGSizeMake(maxWidth, DBL_MAX),
    nullptr
  );
  
  return CGSizeMake(maxWidth, suggestedSize.height);
}

// make sure the newest state is kept in _state property
- (void)updateState:(State::Shared const &)state oldState:(State::Shared const &)oldState {
  _state = std::static_pointer_cast<const ReactNativeRichTextEditorViewShadowNode::ConcreteState>(state);
  
  // first render with all the needed stuff already defined (state and componentView)
  // so we need to run a single height calculation for any initial values
  if(oldState == nullptr) {
    [self tryUpdatingHeight];
  }
}

- (void)tryUpdatingHeight {
  if(_state == nullptr) {
    return;
  }
  _componentViewHeightUpdateCounter++;
  auto selfRef = wrapManagedObjectWeakly(self);
  _state->updateState(ReactNativeRichTextEditorViewState(_componentViewHeightUpdateCounter, selfRef));
}

// MARK: - Active styles

- (void)tryUpdatingActiveStyles {
  // style updates are emitted only if something differs from the previously active styles
  BOOL updateNeeded = NO;
  
  // data for onLinkDetected event
  LinkData *detectedLinkData;
  NSRange detectedLinkRange = NSMakeRange(0, 0);
  
  // data for onMentionDetected event
  MentionParams *detectedMentionParams;
  NSRange detectedMentionRange = NSMakeRange(0, 0);

  for (NSNumber* type in stylesDict) {
    id<BaseStyleProtocol> style = stylesDict[type];
    BOOL wasActive = [_activeStyles containsObject: type];
    BOOL isActive = [style detectStyle:textView.selectedRange];
    if(wasActive != isActive) {
      updateNeeded = YES;
      if(isActive) {
        [_activeStyles addObject:type];
      } else {
        [_activeStyles removeObject:type];
      }
    }
    
    // onLinkDetected event
    if(isActive && [type intValue] == [LinkStyle getStyleType]) {
      // get the link data
      LinkData *candidateLinkData;
      NSRange candidateLinkRange = NSMakeRange(0, 0);
      LinkStyle *linkStyleClass = (LinkStyle *)stylesDict[@([LinkStyle getStyleType])];
      if(linkStyleClass != nullptr) {
        candidateLinkData = [linkStyleClass getLinkDataAt:textView.selectedRange.location];
        candidateLinkRange = [linkStyleClass getFullLinkRangeAt:textView.selectedRange.location];
      }
      
      if(wasActive == NO) {
        // we changed selection from non-link to a link
        detectedLinkData = candidateLinkData;
        detectedLinkRange = candidateLinkRange;
      } else if(
        ![_recentlyActiveLinkData.url isEqualToString:candidateLinkData.url] ||
        ![_recentlyActiveLinkData.text isEqualToString:candidateLinkData.text] ||
        !NSEqualRanges(_recentlyActiveLinkRange, candidateLinkRange)
      ) {
        // we changed selection from one link to the other or modified current link's text
        detectedLinkData = candidateLinkData;
        detectedLinkRange = candidateLinkRange;
      }
    }
    
    // onMentionDetected event
    if(isActive && [type intValue] == [MentionStyle getStyleType]) {
      // get mention data
      MentionParams *candidateMentionParams;
      NSRange candidateMentionRange = NSMakeRange(0, 0);
      MentionStyle *mentionStyleClass = (MentionStyle *)stylesDict[@([MentionStyle getStyleType])];
      if(mentionStyleClass != nullptr) {
        candidateMentionParams = [mentionStyleClass getMentionParamsAt:textView.selectedRange.location];
        candidateMentionRange = [mentionStyleClass getFullMentionRangeAt:textView.selectedRange.location];
      }
      
      if(wasActive == NO) {
        // selection was changed from a non-mention to a mention
        detectedMentionParams = candidateMentionParams;
        detectedMentionRange = candidateMentionRange;
      } else if(
        ![_recentlyActiveMentionParams.text isEqualToString:candidateMentionParams.text] ||
        ![_recentlyActiveMentionParams.attributes isEqualToString:candidateMentionParams.attributes] ||
        !NSEqualRanges(_recentlyActiveMentionRange, candidateMentionRange)
      ) {
        // selection changed from one mention to another
        detectedMentionParams = candidateMentionParams;
        detectedMentionRange = candidateMentionRange;
      }
    }
  }
    
  if(updateNeeded) {
    auto emitter = [self getEventEmitter];
    if(emitter != nullptr) {
      emitter->onChangeState({
        .isBold = [_activeStyles containsObject: @([BoldStyle getStyleType])],
        .isItalic = [_activeStyles containsObject: @([ItalicStyle getStyleType])],
        .isUnderline = [_activeStyles containsObject: @([UnderlineStyle getStyleType])],
        .isStrikeThrough = [_activeStyles containsObject: @([StrikethroughStyle getStyleType])],
        .isInlineCode = [_activeStyles containsObject: @([InlineCodeStyle getStyleType])],
        .isLink = [_activeStyles containsObject: @([LinkStyle getStyleType])],
        .isMention = [_activeStyles containsObject: @([MentionStyle getStyleType])],
        .isH1 = NO, // [_activeStyles containsObject: @([H1Style getStyleType])],
        .isH2 = NO, // [_activeStyles containsObject: @([H2Style getStyleType])],
        .isH3 = NO, // [_activeStyles containsObject: @([H3Style getStyleType])],
        .isCodeBlock = NO, // [_activeStyles containsObject: @([CodeBlockStyle getStyleType])],
        .isBlockQuote = NO, // [_activeStyles containsObject: @([BlockQuoteStyle getStyleType])],
        .isUnorderedList = NO, // [_activeStyles containsObject: @([UnorderedListStyle getStyleType])],
        .isOrderedList = NO, // [_activeStyles containsObject: @([OrderedListStyle getStyleType]]],
        .isImage = NO // [_activeStyles containsObject: @([ImageStyle getStyleType]]],
      });
    }
  }
  
  if(detectedLinkData != nullptr) {
    // emit onLinkeDetected event
    [self emitOnLinkDetectedEvent:detectedLinkData.text url:detectedLinkData.url];
    
    _recentlyActiveLinkData = detectedLinkData;
    _recentlyActiveLinkRange = detectedLinkRange;
  }
  
  if(detectedMentionParams != nullptr) {
    // emit onMentionDetected event
    [self emitOnMentionDetectedEvent:detectedMentionParams.text attributes:detectedMentionParams.attributes];
    
    _recentlyActiveMentionParams = detectedMentionParams;
    _recentlyActiveMentionRange = detectedMentionRange;
  }
}

// MARK: - Native commands

- (void)handleCommand:(const NSString *)commandName args:(const NSArray *)args {
  if([commandName isEqualToString:@"focus"]) {
    [self focus];
  } else if([commandName isEqualToString:@"blur"]) {
    [self blur];
  } else if([commandName isEqualToString:@"toggleBold"]) {
    [self toggleRegularStyle: [BoldStyle getStyleType]];
  } else if([commandName isEqualToString:@"toggleItalic"]) {
    [self toggleRegularStyle: [ItalicStyle getStyleType]];
  } else if([commandName isEqualToString:@"toggleUnderline"]) {
    [self toggleRegularStyle: [UnderlineStyle getStyleType]];
  } else if([commandName isEqualToString:@"toggleStrikeThrough"]) {
    [self toggleRegularStyle: [StrikethroughStyle getStyleType]];
  } else if([commandName isEqualToString:@"toggleInlineCode"]) {
    [self toggleRegularStyle: [InlineCodeStyle getStyleType]];
  } else if([commandName isEqualToString:@"addLink"]) {
    NSInteger start = [((NSNumber*)args[0]) integerValue];
    NSInteger end = [((NSNumber*)args[1]) integerValue];
    NSString *text = (NSString *)args[2];
    NSString *url = (NSString *)args[3];
    [self addLinkAt:start end:end text:text url:url];
  } else if([commandName isEqualToString:@"addMention"]) {
    NSString *text = (NSString *)args[0];
    NSString *attributes = (NSString *)args[1];
    [self addMentionWithText:text attributes:attributes];
  } else if([commandName isEqualToString:@"startMention"]) {
    NSString *indicator = (NSString *)args[0];
    [self startMentionWithIndicator:indicator];
  }
}

- (std::shared_ptr<ReactNativeRichTextEditorViewEventEmitter>)getEventEmitter {
  if(_eventEmitter != nullptr) {
    auto emitter = static_cast<const ReactNativeRichTextEditorViewEventEmitter &>(*_eventEmitter);
    return std::make_shared<ReactNativeRichTextEditorViewEventEmitter>(emitter);
  } else {
    return nullptr;
  }
}

- (void)blur {
  [textView reactBlur];
}

- (void)focus {
  [textView reactFocus];
}

- (void)emitOnLinkDetectedEvent:(NSString *)text url:(NSString *)url {
  auto emitter = [self getEventEmitter];
  if(emitter != nullptr) {
    emitter->onLinkDetected({
      .text = [text toCppString],
      .url = [url toCppString]
    });
  }
}

- (void)emitOnMentionDetectedEvent:(NSString *)text attributes:(NSString *)attributes {
  auto emitter = [self getEventEmitter];
  if(emitter != nullptr) {
    emitter->onMentionDetected({
      .text = [text toCppString],
      .payload = [attributes toCppString]
    });
  }
}

- (void)emitOnMentionEvent:(NSString *)indicator text:(NSString *)text {
  auto emitter = [self getEventEmitter];
  if(emitter != nullptr) {
    if(text != nullptr) {
      folly::dynamic fdStr = [text toCppString];
      emitter->onMention({
        .indicator = [indicator toCppString],
        .text = fdStr
      });
    } else {
      folly::dynamic nul = nullptr;
      emitter->onMention({
        .indicator = [indicator toCppString],
        .text = nul
      });
    }
  }
}

// MARK: - Styles manipulation

- (void)toggleRegularStyle:(StyleType)type {
  id<BaseStyleProtocol> styleClass = stylesDict[@(type)];
  
  if([self handleStyleBlocksAndConflicts:type range:textView.selectedRange]) {
    [styleClass applyStyle:textView.selectedRange];
    [self tryUpdatingActiveStyles];
  }
}

- (void)addLinkAt:(NSInteger)start end:(NSInteger)end text:(NSString *)text url:(NSString *)url {
  LinkStyle *linkStyleClass = (LinkStyle *)stylesDict[@([LinkStyle getStyleType])];
  if(linkStyleClass == nullptr) { return; }
  
  // translate the output start-end notation to range
  NSRange linkRange = NSMakeRange(start, end - start);
  if([self handleStyleBlocksAndConflicts:[LinkStyle getStyleType] range:linkRange]) {
    [linkStyleClass addLink:text url:url range:linkRange manual:YES];
    [self tryUpdatingActiveStyles];
  }
}

- (void)addMentionWithText:(NSString *)text attributes:(NSString *)attributes {
  MentionStyle *mentionStyleClass = (MentionStyle *)stylesDict[@([MentionStyle getStyleType])];
  if(mentionStyleClass == nullptr) { return; }
  if([mentionStyleClass getActiveMentionRange] == nullptr) { return; }
  
  if([self handleStyleBlocksAndConflicts:[MentionStyle getStyleType] range:[[mentionStyleClass getActiveMentionRange] rangeValue]]) {
    [mentionStyleClass addMentionWithText:text attributes:attributes];
    [self tryUpdatingActiveStyles];
  }
}

- (void)startMentionWithIndicator:(NSString *)indicator {
  MentionStyle *mentionStyleClass = (MentionStyle *)stylesDict[@([MentionStyle getStyleType])];
  if(mentionStyleClass == nullptr) { return; }
  
  if([self handleStyleBlocksAndConflicts:[MentionStyle getStyleType] range:[[mentionStyleClass getActiveMentionRange] rangeValue]]) {
    [mentionStyleClass startMentionWithIndicator:indicator];
    [self tryUpdatingActiveStyles];
  }
}

// returns false when style shouldn't be applied and true when it can be
- (BOOL)handleStyleBlocksAndConflicts:(StyleType)type range:(NSRange)range {
  // handle blocking styles: if any is present we do not apply the toggled style
  NSArray<NSNumber *> *blocking = [self getPresentStyleTypesFrom: blockingStyles[@(type)]];
  if(blocking.count != 0) {
    return NO;
  }
  
  // handle conflicting styles: all of their occurences have to be removed
  NSArray<NSNumber *> *conflicting = [self getPresentStyleTypesFrom: conflictingStyles[@(type)]];
  if(conflicting.count != 0) {
    for(NSNumber *style in conflicting) {
      id<BaseStyleProtocol> styleClass = stylesDict[style];
      
      if(range.length >= 1) {
        // for ranges, we need to remove each occurence
        NSArray<StylePair *> *allOccurences = [styleClass findAllOccurences:range];
        
        for(StylePair* pair in allOccurences) {
          [styleClass removeAttributes: [pair.rangeValue rangeValue]];
        }
      } else {
        // with in-place selection, we just remove the adequate typing attributes
        [styleClass removeTypingAttributes];
      }
    }
  }
  return YES;
}

- (NSArray<NSNumber *> *)getPresentStyleTypesFrom:(NSArray<NSNumber *> *)types {
  NSMutableArray<NSNumber *> *resultArray = [[NSMutableArray<NSNumber *> alloc] init];
  for(NSNumber *type in types) {
    id<BaseStyleProtocol> styleClass = stylesDict[type];
    
    if(textView.selectedRange.length >= 1) {
      if([styleClass anyOccurence:textView.selectedRange]) {
        [resultArray addObject:type];
      }
    } else {
      if([styleClass detectStyle:textView.selectedRange]) {
        [resultArray addObject:type];
      }
    }
  }
  return resultArray;
}

- (void)manageSelectionBasedChanges {
  // link typing attributes fix
  LinkStyle *linkStyleClass = (LinkStyle *)stylesDict[@([LinkStyle getStyleType])];
  if(linkStyleClass != nullptr) {
    [linkStyleClass manageLinkTypingAttributes];
  }
  
  // mention typing attribtues fix and active editing
  MentionStyle *mentionStyleClass = (MentionStyle *)stylesDict[@([MentionStyle getStyleType])];
  if(mentionStyleClass != nullptr) {
    [mentionStyleClass manageMentionTypingAttributes];
    [mentionStyleClass manageMentionEditing];
  }
}

- (void)handleWordModificationBasedChanges:(NSString*)word inRange:(NSRange)range {
  // manual links refreshing and automatic links detection handling
  LinkStyle* linkStyle = [stylesDict objectForKey:@([LinkStyle getStyleType])];
  if(linkStyle != nullptr) {
    // manual links need to be handled first because they can block automatic links after being refreshed
    [linkStyle handleManualLinks:word inRange:range];
    [linkStyle handleAutomaticLinks:word inRange:range];
  }
  
  // mentions removal in case of some invalid modifications
  MentionStyle *mentionStyleClass = (MentionStyle *)stylesDict[@([MentionStyle getStyleType])];
  if(mentionStyleClass != nullptr) {
    [mentionStyleClass handleExistingMentions];
  }
}

// MARK: - UITextView delegate methods

- (void)textViewDidBeginEditing:(UITextView *)textView {
  auto emitter = [self getEventEmitter];
  if(emitter != nullptr) {
    //send onFocus event
    emitter->onInputFocus({});
    
    NSString *textAtSelection = [[[NSMutableString alloc] initWithString:textView.textStorage.string] substringWithRange: textView.selectedRange];
    emitter->onChangeSelection({
      .start = static_cast<int>(textView.selectedRange.location),
      .end = static_cast<int>(textView.selectedRange.location + textView.selectedRange.length),
      .text = [textAtSelection toCppString]
    });
  }
  // manage selection changes since textViewDidChangeSelection sometimes doesn't run on focus
  [self manageSelectionBasedChanges];
}

- (void)textViewDidEndEditing:(UITextView *)textView {
  auto emitter = [self getEventEmitter];
  if(emitter != nullptr) {
    //send onBlur event
    emitter->onInputBlur({});
  }
}

- (bool)textView:(UITextView *)textView shouldChangeTextInRange:(NSRange)range replacementText:(NSString *)text {
  _recentlyChangedRange = NSMakeRange(range.location, text.length);
  return true;
}

- (void)textViewDidChangeSelection:(UITextView *)textView {
  // emit the event
  NSString *textAtSelection = [[[NSMutableString alloc] initWithString:textView.textStorage.string] substringWithRange: textView.selectedRange];
    
  auto emitter = [self getEventEmitter];
  if(emitter != nullptr) {
    // iOS range works differently because it specifies location and length
    // here, start is the location, but end is the first index BEHIND the end. So a 0 length range will have equal start and end
    emitter->onChangeSelection({
      .start = static_cast<int>(textView.selectedRange.location),
      .end = static_cast<int>(textView.selectedRange.location + textView.selectedRange.length),
      .text = [textAtSelection toCppString]
    });
  }
  
  // manage selection changes
  [self manageSelectionBasedChanges];
  
  // update active styles
  [self tryUpdatingActiveStyles];
}

- (void)textViewDidChange:(UITextView *)textView {
  // revert typing attributes to the defaults if field is empty
  if(textView.textStorage.length == 0) {
    textView.typingAttributes = _defaultTypingAttributes;
  }

  // fix the marked text issues
  if(textView.markedTextRange != nullptr) {
    // when there is some sort of system marking, we don't process modified words
    // and no text event is emitted
    _modifiedWords = nullptr;
  } else {
    // normally compute modified words
    _modifiedWords = [WordsUtils getAffectedWordsFromText:textView.textStorage.string modificationRange:_recentlyChangedRange];
    
    // emit the event only when the values differ
    if(![textView.textStorage.string isEqualToString:_recentlyEmittedString]) {
      _recentlyEmittedString = [textView.textStorage.string copy];
      auto emitter = [self getEventEmitter];
      if(emitter != nullptr) {
        emitter->onChangeText({
          .value = [textView.textStorage.string toCppString]
        });
      }
    }
  }
  
  // handle modified words
  if(_modifiedWords != nullptr) {
    for(NSDictionary *wordDict in _modifiedWords) {
      NSString *wordText = (NSString *)[wordDict objectForKey:@"word"];
      NSValue *wordRange = (NSValue *)[wordDict objectForKey:@"range"];
      
      if(wordText == nullptr || wordRange == nullptr) {
        continue;
      }
      
      [self handleWordModificationBasedChanges:wordText inRange:[wordRange rangeValue]];
    }
  }
  
  // update height on each character change
  [self tryUpdatingHeight];
  // for safety: update active styles as well
  [self tryUpdatingActiveStyles];
}

@end
