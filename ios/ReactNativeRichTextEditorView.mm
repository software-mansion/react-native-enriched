#import "ReactNativeRichTextEditorView.h"
#import "RCTFabricComponentsPlugins.h"
#import <ReactNativeRichTextEditor/ReactNativeRichTextEditorViewComponentDescriptor.h>
#import <ReactNativeRichTextEditor/EventEmitters.h>
#import <ReactNativeRichTextEditor/Props.h>
#import <ReactNativeRichTextEditor/RCTComponentViewHelpers.h>
#import <react/utils/ManagedObjectWrapper.h>
#import "UIView+React.h"
#import "StringUtils.h"
#import "CoreText/CoreText.h"
#import <React/RCTConvert.h>
#import "StyleHeaders.h"

using namespace facebook::react;

@interface ReactNativeRichTextEditorView () <RCTReactNativeRichTextEditorViewViewProtocol, UITextViewDelegate, NSObject>

@end

@implementation ReactNativeRichTextEditorView {
  ReactNativeRichTextEditorViewShadowNode::ConcreteState::Shared _state;
  int _componentViewHeightUpdateCounter;
  NSMutableDictionary<NSAttributedStringKey, id> *_defaultTypingAttributes;
  NSMutableSet<NSNumber *> *_activeStyles;
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
  currentRange = NSMakeRange(0, 0);
  stylesDict = @{
    [NSNumber numberWithInteger:Bold] : [[BoldStyle alloc] initWithEditor: self]
  };
  _activeStyles = [[NSMutableSet alloc] init];
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
  BOOL heightUpdateNeeded = false;
  
  // initial config
  // TODO: handle reacting to config props when styles are relatively working
  if(config == nullptr) {
    EditorConfig *newConfig = [[EditorConfig alloc] init];
  
    if(newViewProps.color) {
      int32_t colorInt = (*(newViewProps.color)).getColor();
      NSNumber* nsColor = [[NSNumber alloc] initWithInt:colorInt];
      UIColor *color = [RCTConvert UIColor: nsColor];
      [newConfig setPrimaryColor:color];
    }
    
    if(newViewProps.fontSize) {
      NSNumber* fontSize = [[NSNumber alloc] initWithFloat: newViewProps.fontSize];
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
    textView.typingAttributes = _defaultTypingAttributes;
  }
  
  // default value
  if(newViewProps.defaultValue != oldViewProps.defaultValue) {
    textView.text = [NSString fromCppString:newViewProps.defaultValue];
    heightUpdateNeeded = true;
  }
  
  [super updateProps:props oldProps:oldProps];
  
  if(heightUpdateNeeded) {
    [self tryUpdatingHeight];
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

  for (NSNumber* type in stylesDict) {
    id<BaseStyleProtocol> style = stylesDict[type];
    BOOL wasActive = [_activeStyles containsObject: type];
    BOOL isActive = [style detectStyle:currentRange];
    if(wasActive != isActive) {
      updateNeeded = YES;
      if(isActive) {
        [_activeStyles addObject:type];
      } else {
        [_activeStyles removeObject:type];
      }
    }
  }
    
  if(updateNeeded) {
    static_cast<const ReactNativeRichTextEditorViewEventEmitter &>(*_eventEmitter).onChangeStyle({
      .isBold = [_activeStyles containsObject: [NSNumber numberWithInt:[BoldStyle getStyleType]]],
      .isItalic = NO, //[_activeStyles containsObject: [NSNumber numberWithInt:[ItalicStyler getStyleType]]],
      .isUnderline = NO, // [_activeStyles containsObject: [NSNumber numberWithInt:[UnderlineStyle getStyleType]]],
      .isStrikeThrough = NO, // [_activeStyles containsObject: [NSNumber numberWithInt:[StrikethroughStyle getStyleType]]],
      .isInlineCode = NO, // [_activeStyles containsObject: [NSNumber numberWithInt:[InlineCodeStyle getStyleType]]],
      .isLink = NO, // [_activeStyles containsObject: [NSNumber numberWithInt:[LinkStyle getStyleType]]],
      //.isMention = [_activeStyles containsObject: [NSNumber numberWithInt:[MentionStyle getStyleType]]],
      .isH1 = NO, // [_activeStyles containsObject: [NSNumber numberWithInt:[H1Style getStyleType]]],
      .isH2 = NO, // [_activeStyles containsObject: [NSNumber numberWithInt:[H2Style getStyleType]]],
      .isH3 = NO, // [_activeStyles containsObject: [NSNumber numberWithInt:[H3Style getStyleType]]],
      .isCodeBlock = NO, // [_activeStyles containsObject: [NSNumber numberWithInt:[CodeBlockStyle getStyleType]]],
      .isBlockQuote = NO, // [_activeStyles containsObject: [NSNumber numberWithInt:[BlockQuoteStyle getStyleType]]],
      .isUnorderedList = NO, // [_activeStyles containsObject: [NSNumber numberWithInt:[UnorderedListStyle getStyleType]]],
      .isOrderedList = NO, // [_activeStyles containsObject: [NSNumber numberWithInt:[OrderedListStyle getStyleType]]],
      .isImage = NO // [_activeStyles containsObject: [NSNumber numberWithInt:[ImageStyle getStyleType]]],
    });
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
  }
}

- (void)blur {
  [textView reactBlur];
}

- (void)focus {
  [textView reactFocus];
}

- (void)toggleRegularStyle:(StyleType)type {
  id<BaseStyleProtocol> styleClass = stylesDict[[NSNumber numberWithInt:type]];
  [styleClass applyStyle:currentRange];
  [self tryUpdatingActiveStyles];
}

// MARK: - UITextView delegate methods

- (bool)textView:(UITextView *)textView shouldChangeTextInRange:(NSRange)range replacementText:(NSString *)text {
  NSMutableString *newText = [[NSMutableString alloc] initWithString:textView.textStorage.string];
  [newText replaceCharactersInRange:range withString:text];
  
  static_cast<const ReactNativeRichTextEditorViewEventEmitter &>(*_eventEmitter)
    .onChangeText({ .value = [newText toCppString]});
  
  return true;
}

- (void)textViewDidChangeSelection:(UITextView *)textView {
  // update current range
  currentRange = textView.selectedRange;
  // update active styles
  [self tryUpdatingActiveStyles];
}

- (void)textViewDidChange:(UITextView *)textView {
  BOOL needsActiveStylesUpdate = NO;

  // revert typing attributes to the defaults if field is empty
  if(textView.textStorage.string.length == 0) {
    textView.typingAttributes = _defaultTypingAttributes;
    needsActiveStylesUpdate = YES;
  }
  
  // update height on each character change
  [self tryUpdatingHeight];
  // update active styles if needed
  if(needsActiveStylesUpdate) {
    [self tryUpdatingActiveStyles];
  }
}

@end
