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
#import "EditorParser.h"

using namespace facebook::react;

@interface ReactNativeRichTextEditorView () <RCTReactNativeRichTextEditorViewViewProtocol, UITextViewDelegate, NSObject>

@end

@implementation ReactNativeRichTextEditorView {
  ReactNativeRichTextEditorViewShadowNode::ConcreteState::Shared _state;
  int _componentViewHeightUpdateCounter;
  NSMutableSet<NSNumber *> *_activeStyles;
  NSDictionary<NSNumber *, NSArray<NSNumber *> *> *_conflictingStyles;
  NSDictionary<NSNumber *, NSArray<NSNumber *> *> *_blockingStyles;
  LinkData *_recentlyActiveLinkData;
  NSRange _recentlyActiveLinkRange;
  NSRange _recentlyChangedRange;
  NSString *_recentlyEmittedString;
  MentionParams *_recentlyActiveMentionParams;
  NSRange _recentlyActiveMentionRange;
  EditorParser *_editorParser;
  NSString *_recentlyEmittedHtml;
  BOOL _emitHtml;
  UILabel *_placeholderLabel;
  UIColor *_placeholderColor;
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
    [self setupPlaceholderLabel];
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
  _recentlyEmittedHtml = @"";
  _emitHtml = NO;
  blockEmitting = NO;
  
  defaultTypingAttributes = [[NSMutableDictionary<NSAttributedStringKey, id> alloc] init];
  
  stylesDict = @{
    @([BoldStyle getStyleType]) : [[BoldStyle alloc] initWithEditor:self],
    @([ItalicStyle getStyleType]): [[ItalicStyle alloc] initWithEditor:self],
    @([UnderlineStyle getStyleType]): [[UnderlineStyle alloc] initWithEditor:self],
    @([StrikethroughStyle getStyleType]): [[StrikethroughStyle alloc] initWithEditor:self],
    @([InlineCodeStyle getStyleType]): [[InlineCodeStyle alloc] initWithEditor:self],
    @([LinkStyle getStyleType]): [[LinkStyle alloc] initWithEditor:self],
    @([MentionStyle getStyleType]): [[MentionStyle alloc] initWithEditor:self],
    @([H1Style getStyleType]): [[H1Style alloc] initWithEditor:self],
    @([H2Style getStyleType]): [[H2Style alloc] initWithEditor:self],
    @([H3Style getStyleType]): [[H3Style alloc] initWithEditor:self],
    @([UnorderedListStyle getStyleType]): [[UnorderedListStyle alloc] initWithEditor:self]
  };
  
  _conflictingStyles = @{
    @([BoldStyle getStyleType]) : @[],
    @([ItalicStyle getStyleType]) : @[],
    @([UnderlineStyle getStyleType]) : @[],
    @([StrikethroughStyle getStyleType]) : @[],
    @([InlineCodeStyle getStyleType]) : @[@([LinkStyle getStyleType]), @([MentionStyle getStyleType])],
    @([LinkStyle getStyleType]): @[@([InlineCodeStyle getStyleType]), @([LinkStyle getStyleType]), @([MentionStyle getStyleType])],
    @([MentionStyle getStyleType]): @[@([InlineCodeStyle getStyleType]), @([LinkStyle getStyleType])],
    @([H1Style getStyleType]): @[@([H2Style getStyleType]), @([H3Style getStyleType]), @([UnorderedListStyle getStyleType])],
    @([H2Style getStyleType]): @[@([H1Style getStyleType]), @([H3Style getStyleType]), @([UnorderedListStyle getStyleType])],
    @([H3Style getStyleType]): @[@([H1Style getStyleType]), @([H2Style getStyleType]), @([UnorderedListStyle getStyleType])],
    @([UnorderedListStyle getStyleType]): @[@([H1Style getStyleType]), @([H2Style getStyleType]), @([H3Style getStyleType])],
  };
  
  _blockingStyles = @{
    @([BoldStyle getStyleType]) : @[],
    @([ItalicStyle getStyleType]) : @[],
    @([UnderlineStyle getStyleType]) : @[],
    @([StrikethroughStyle getStyleType]) : @[],
    @([InlineCodeStyle getStyleType]) : @[],
    @([LinkStyle getStyleType]): @[],
    @([MentionStyle getStyleType]): @[],
    @([H1Style getStyleType]): @[],
    @([H2Style getStyleType]): @[],
    @([H3Style getStyleType]): @[],
    @([UnorderedListStyle getStyleType]): @[],
  };
  
  _editorParser = [[EditorParser alloc] initWithEditor:self];
}

- (void)setupTextView {
  textView = [[UITextView alloc] init];
  textView.backgroundColor = UIColor.clearColor;
  textView.textContainerInset = UIEdgeInsetsMake(0, 0, 0, 0);
  textView.textContainer.lineFragmentPadding = 0;
  textView.delegate = self;
}

- (void)setupPlaceholderLabel {
  _placeholderLabel = [[UILabel alloc] initWithFrame:CGRectZero];
  _placeholderLabel.translatesAutoresizingMaskIntoConstraints = NO;
  [textView addSubview:_placeholderLabel];
  [NSLayoutConstraint activateConstraints: @[
    [_placeholderLabel.leadingAnchor constraintEqualToAnchor:textView.leadingAnchor],
    [_placeholderLabel.widthAnchor constraintEqualToAnchor:textView.widthAnchor],
    [_placeholderLabel.topAnchor constraintEqualToAnchor:textView.topAnchor],
    [_placeholderLabel.bottomAnchor constraintEqualToAnchor:textView.bottomAnchor]
  ]];
  _placeholderLabel.lineBreakMode = NSLineBreakByTruncatingTail;
  _placeholderLabel.text = @"";
  _placeholderLabel.hidden = YES;
}

// MARK: - Props

- (void)updateProps:(Props::Shared const &)props oldProps:(Props::Shared const &)oldProps {
  const auto &oldViewProps = *std::static_pointer_cast<ReactNativeRichTextEditorViewProps const>(_props);
  const auto &newViewProps = *std::static_pointer_cast<ReactNativeRichTextEditorViewProps const>(props);
  BOOL isFirstMount = NO;
  BOOL stylePropChanged = NO;
  
  // initial config
  if(config == nullptr) {
    isFirstMount = YES;
    config = [[EditorConfig alloc] init];
  }
  
  // style props:
  
  if(newViewProps.color != oldViewProps.color) {
    if(isColorMeaningful(newViewProps.color)) {
      UIColor *uiColor = RCTUIColorFromSharedColor(newViewProps.color);
      [config setPrimaryColor:uiColor];
    } else {
      [config setPrimaryColor:nullptr];
    }
    stylePropChanged = YES;
  }
  
  if(newViewProps.fontSize != oldViewProps.fontSize) {
    if(newViewProps.fontSize) {
      NSNumber* fontSize = @(newViewProps.fontSize);
      [config setPrimaryFontSize:fontSize];
    } else {
      [config setPrimaryFontSize:nullptr];
    }
    stylePropChanged = YES;
  }
  
  if(newViewProps.fontWeight != oldViewProps.fontWeight) {
    if(!newViewProps.fontWeight.empty()) {
      [config setPrimaryFontWeight:[NSString fromCppString:newViewProps.fontWeight]];
    } else {
      [config setPrimaryFontWeight:nullptr];
    }
    stylePropChanged = YES;
  }
    
  if(newViewProps.fontFamily != oldViewProps.fontFamily) {
    if(!newViewProps.fontFamily.empty()) {
      [config setPrimaryFontFamily:[NSString fromCppString:newViewProps.fontFamily]];
    } else {
      [config setPrimaryFontFamily:nullptr];
    }
    stylePropChanged = YES;
  }
    
  // fill the typing attributes with style props
  defaultTypingAttributes[NSForegroundColorAttributeName] = [config primaryColor];
  defaultTypingAttributes[NSFontAttributeName] = [config primaryFont];
  defaultTypingAttributes[NSUnderlineColorAttributeName] = [config primaryColor];
  defaultTypingAttributes[NSStrikethroughColorAttributeName] = [config primaryColor];
  defaultTypingAttributes[NSParagraphStyleAttributeName] = [[NSParagraphStyle alloc] init];
  textView.typingAttributes = defaultTypingAttributes;
  
  if(stylePropChanged) {
    // all the text needs to be rebuilt
    // we get the current html and replace whole text parsing it back into the input
    // this way, the newest config attributes are being used!
    NSString *currentHtml = [_editorParser parseToHtml];
    
    // we don't want to emit these html changes in here
    _emitHtml = NO;
    [_editorParser replaceWholeFromHtml:currentHtml];
    _emitHtml = YES;
    
    // update the placeholder as well
    [self refreshPlaceholderLabelStyles];
  }
  
  // editable
  if(newViewProps.editable != oldViewProps.editable) {
    textView.editable = newViewProps.editable;
  }
  
  // default value - must be set before placeholder to make sure it correctly shows on first mount
  if(newViewProps.defaultValue != oldViewProps.defaultValue) {
    NSString *newDefaultValue = [NSString fromCppString:newViewProps.defaultValue];
    if(newDefaultValue.length >= 13) {
      NSString *firstSix = [newDefaultValue substringWithRange:NSMakeRange(0, 6)];
      NSString *lastSeven = [newDefaultValue substringWithRange:NSMakeRange(newDefaultValue.length - 7, 7)];
      
      if([firstSix isEqualToString:@"<html>"] && [lastSeven isEqualToString:@"</html>"]) {
        // we've got some seemingly proper html
        [_editorParser replaceWholeFromHtml:newDefaultValue];
      } else {
        textView.text = newDefaultValue;
      }
    } else {
      textView.text = newDefaultValue;
    }
  }
  
  // placeholderTextColor
  if(newViewProps.placeholderTextColor != oldViewProps.placeholderTextColor) {
    // some real color
    if(isColorMeaningful(newViewProps.placeholderTextColor)) {
      _placeholderColor = RCTUIColorFromSharedColor(newViewProps.placeholderTextColor);
    } else {
      _placeholderColor = nullptr;
    }
    [self refreshPlaceholderLabelStyles];
  }
  
  // placeholder
  if(newViewProps.placeholder != oldViewProps.placeholder) {
    _placeholderLabel.text = [NSString fromCppString:newViewProps.placeholder];
    [self refreshPlaceholderLabelStyles];
    // additionally show placeholder on first mount if it should be there
    if(isFirstMount && textView.text.length == 0) {
      [self setPlaceholderLabelShown:YES];
    }
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
  
  // selection color sets both selection and cursor on iOS (just as in RN)
  if(newViewProps.selectionColor != oldViewProps.selectionColor) {
    if(isColorMeaningful(newViewProps.selectionColor)) {
      textView.tintColor = RCTUIColorFromSharedColor(newViewProps.selectionColor);
    } else {
      textView.tintColor = nullptr;
    }
  }
  
  // isOnChangeHtmlSet
  _emitHtml = newViewProps.isOnChangeHtmlSet;
  
  [super updateProps:props oldProps:oldProps];
  // mandatory text and height checks
  [self anyTextMayHaveBeenModified];
  [self tryUpdatingHeight];
  
  // autofocus - needs to be done at the very end
  if(isFirstMount && newViewProps.autoFocus) {
    [textView reactFocus];
  }
}

- (void)setPlaceholderLabelShown:(BOOL)shown {
  if(shown) {
    [self refreshPlaceholderLabelStyles];
    _placeholderLabel.hidden = NO;
  } else {
    _placeholderLabel.hidden = YES;
  }
}

- (void)refreshPlaceholderLabelStyles {
  NSMutableDictionary *newAttrs = [defaultTypingAttributes mutableCopy];
  if(_placeholderColor != nullptr) {
    newAttrs[NSForegroundColorAttributeName] = _placeholderColor;
  }
  NSAttributedString *newAttrStr = [[NSAttributedString alloc] initWithString:_placeholderLabel.text attributes: newAttrs];
  _placeholderLabel.attributedText = newAttrStr;
}

// MARK: - Measuring and states

- (CGSize)measureSize:(CGFloat)maxWidth {
  // copy the the whole attributed string
  NSMutableAttributedString *currentStr = [[NSMutableAttributedString alloc] initWithAttributedString:textView.textStorage];
  
  // edge case: empty input should still be of a height of a single line, so we add a mock "I" character
  if([currentStr length] == 0 ) {
    [currentStr appendAttributedString:
       [[NSAttributedString alloc] initWithString:@"I" attributes:textView.typingAttributes]
    ];
  }
  
  // edge case: trailing newlines aren't counted towards height calculations, so we add a mock "I" character
  if(currentStr.length > 0) {
    unichar lastChar = [currentStr.string characterAtIndex:currentStr.length-1];
    if([[NSCharacterSet newlineCharacterSet] characterIsMember:lastChar]) {
      [currentStr appendAttributedString:
        [[NSAttributedString alloc] initWithString:@"I" attributes:textView.typingAttributes]
      ];
    }
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
        .isH1 = [_activeStyles containsObject: @([H1Style getStyleType])],
        .isH2 = [_activeStyles containsObject: @([H2Style getStyleType])],
        .isH3 = [_activeStyles containsObject: @([H3Style getStyleType])],
        .isCodeBlock = NO, // [_activeStyles containsObject: @([CodeBlockStyle getStyleType])],
        .isBlockQuote = NO, // [_activeStyles containsObject: @([BlockQuoteStyle getStyleType])],
        .isUnorderedList = [_activeStyles containsObject: @([UnorderedListStyle getStyleType])],
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
    [self emitOnMentionDetectedEvent:detectedMentionParams.text indicator:detectedMentionParams.indicator attributes:detectedMentionParams.attributes];
    
    _recentlyActiveMentionParams = detectedMentionParams;
    _recentlyActiveMentionRange = detectedMentionRange;
  }
  
  // emit onChangeHtml event if needed
  [self tryEmittingOnChangeHtmlEvent];
}

// MARK: - Native commands and events

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
    NSString *indicator = (NSString *)args[0];
    NSString *text = (NSString *)args[1];
    NSString *attributes = (NSString *)args[2];
    [self addMention:indicator text:text attributes:attributes];
  } else if([commandName isEqualToString:@"startMention"]) {
    NSString *indicator = (NSString *)args[0];
    [self startMentionWithIndicator:indicator];
  } else if([commandName isEqualToString:@"toggleH1"]) {
    [self toggleParagraphStyle:[H1Style getStyleType]];
  } else if([commandName isEqualToString:@"toggleH2"]) {
    [self toggleParagraphStyle:[H2Style getStyleType]];
  } else if([commandName isEqualToString:@"toggleH3"]) {
    [self toggleParagraphStyle:[H3Style getStyleType]];
  } else if([commandName isEqualToString:@"toggleUnorderedList"]) {
    [self toggleParagraphStyle:[UnorderedListStyle getStyleType]];
  }
}

- (std::shared_ptr<ReactNativeRichTextEditorViewEventEmitter>)getEventEmitter {
  if(_eventEmitter != nullptr && !blockEmitting) {
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

- (void)emitOnMentionDetectedEvent:(NSString *)text indicator:(NSString *)indicator attributes:(NSString *)attributes {
  auto emitter = [self getEventEmitter];
  if(emitter != nullptr) {
    emitter->onMentionDetected({
      .text = [text toCppString],
      .indicator = [indicator toCppString],
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

- (void)tryEmittingOnChangeHtmlEvent {
  if(!_emitHtml || textView.markedTextRange != nullptr) {
    return;
  }
  auto emitter = [self getEventEmitter];
  if(emitter != nullptr) {
    NSString *htmlOutput = [_editorParser parseToHtml];
    // make sure html really changed
    if(![htmlOutput isEqualToString:_recentlyEmittedHtml]) {
      _recentlyEmittedHtml = htmlOutput;
      emitter->onChangeHtml({
        .value = [htmlOutput toCppString]
      });
    }
  }
}

// MARK: - Styles manipulation

- (void)toggleRegularStyle:(StyleType)type {
  id<BaseStyleProtocol> styleClass = stylesDict[@(type)];
  
  if([self handleStyleBlocksAndConflicts:type range:textView.selectedRange]) {
    [styleClass applyStyle:textView.selectedRange];
    [self tryUpdatingHeight];
    [self tryUpdatingActiveStyles];
  }
}

- (void)toggleParagraphStyle:(StyleType)type {
  id<BaseStyleProtocol> styleClass = stylesDict[@(type)];
  // we always pass whole paragraph/s range to these styles
  NSRange paragraphRange = [textView.textStorage.string paragraphRangeForRange:textView.selectedRange];
  
  if([self handleStyleBlocksAndConflicts:type range:paragraphRange]) {
    [styleClass applyStyle:paragraphRange];
    [self tryUpdatingHeight];
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
    [self tryUpdatingHeight];
    [self tryUpdatingActiveStyles];
  }
}

- (void)addMention:(NSString *)indicator text:(NSString *)text attributes:(NSString *)attributes {
  MentionStyle *mentionStyleClass = (MentionStyle *)stylesDict[@([MentionStyle getStyleType])];
  if(mentionStyleClass == nullptr) { return; }
  if([mentionStyleClass getActiveMentionRange] == nullptr) { return; }
  
  if([self handleStyleBlocksAndConflicts:[MentionStyle getStyleType] range:[[mentionStyleClass getActiveMentionRange] rangeValue]]) {
    [mentionStyleClass addMention:indicator text:text attributes:attributes];
    [self tryUpdatingHeight];
    [self tryUpdatingActiveStyles];
  }
}

- (void)startMentionWithIndicator:(NSString *)indicator {
  MentionStyle *mentionStyleClass = (MentionStyle *)stylesDict[@([MentionStyle getStyleType])];
  if(mentionStyleClass == nullptr) { return; }
  
  if([self handleStyleBlocksAndConflicts:[MentionStyle getStyleType] range:[[mentionStyleClass getActiveMentionRange] rangeValue]]) {
    [mentionStyleClass startMentionWithIndicator:indicator];
    [self tryUpdatingHeight];
    [self tryUpdatingActiveStyles];
  }
}

// returns false when style shouldn't be applied and true when it can be
- (BOOL)handleStyleBlocksAndConflicts:(StyleType)type range:(NSRange)range {
  // handle blocking styles: if any is present we do not apply the toggled style
  NSArray<NSNumber *> *blocking = [self getPresentStyleTypesFrom: _blockingStyles[@(type)]];
  if(blocking.count != 0) {
    return NO;
  }
  
  // handle conflicting styles: all of their occurences have to be removed
  NSArray<NSNumber *> *conflicting = [self getPresentStyleTypesFrom: _conflictingStyles[@(type)]];
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

- (void)anyTextMayHaveBeenModified {
  // we don't do no text changes when working with iOS marked text
  if(textView.markedTextRange != nullptr) {
    return;
  }

  // do all the stuff only if the text really changed
  if(![textView.textStorage.string isEqualToString:_recentlyEmittedString]) {
    // emptying input
    if(textView.textStorage.string.length == 0) {
      // reset typing attribtues
      textView.typingAttributes = defaultTypingAttributes;
    }
    
    // placholder management
    if(_recentlyEmittedString.length == 0 && textView.textStorage.string.length > 0) {
      [self setPlaceholderLabelShown:NO];
    } else if(_recentlyEmittedString.length > 0 && textView.textStorage.string.length == 0) {
      [self setPlaceholderLabelShown:YES];
    }
    
    // modified words handling
    NSArray *modifiedWords = [WordsUtils getAffectedWordsFromText:textView.textStorage.string modificationRange:_recentlyChangedRange];
    if(modifiedWords != nullptr) {
      for(NSDictionary *wordDict in modifiedWords) {
        NSString *wordText = (NSString *)[wordDict objectForKey:@"word"];
        NSValue *wordRange = (NSValue *)[wordDict objectForKey:@"range"];
        
        if(wordText == nullptr || wordRange == nullptr) {
          continue;
        }
        
        [self handleWordModificationBasedChanges:wordText inRange:[wordRange rangeValue]];
      }
    }
  
    // emit onChangeText event
    auto emitter = [self getEventEmitter];
    if(emitter != nullptr) {
      emitter->onChangeText({
        .value = [textView.textStorage.string toCppString]
      });
    }
    
    // set the recently emitted string
    _recentlyEmittedString = [textView.textStorage.string copy];
  }
  
  // update height on each character change
  [self tryUpdatingHeight];
  // update active styles as well
  [self tryUpdatingActiveStyles];
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
  
  UnorderedListStyle *uStyle = stylesDict[@([UnorderedListStyle getStyleType])];
  if(uStyle != nullptr) {
    // removing first line list fix
    [uStyle handleBackspaceInRange:range replacementText:text];
    // creating unordered list from "- "
    if([uStyle tryHandlingListShorcutInRange:range replacementText:text]) {
      // we successfully added a list -> so we reject the text change
      return NO;
    }
  }
  
  return YES;
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

// this function isn't called always when some text changes (for example setting link or starting mention with indicator doesn't fire it)
// so all the logic is in anyTextMayHaveBeenModified
- (void)textViewDidChange:(UITextView *)textView {
  [self anyTextMayHaveBeenModified];
}

@end
