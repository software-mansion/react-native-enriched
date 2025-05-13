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
#import "EditorConfig.h"

using namespace facebook::react;

@interface ReactNativeRichTextEditorView () <RCTReactNativeRichTextEditorViewViewProtocol, UITextViewDelegate, NSObject>

@end

@implementation ReactNativeRichTextEditorView {
  UITextView *_textView;
  ReactNativeRichTextEditorViewShadowNode::ConcreteState::Shared _state;
  int _componentViewHeightUpdateCounter;
  EditorConfig *_config;
  NSMutableDictionary<NSAttributedStringKey, id> *_defaultTypingAttributes;
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
    self.contentView = _textView;
  }
  
  return self;
}

- (void)setDefaults {
  _componentViewHeightUpdateCounter = 0;
  
}

- (void)setupTextView {
  _textView = [[UITextView alloc] init];
  _textView.backgroundColor = UIColor.clearColor;
  _textView.textContainerInset = UIEdgeInsetsMake(0, 0, 0, 0);
  _textView.textContainer.lineFragmentPadding = 0;
  _textView.delegate = self;
}

// MARK: - Props

- (void)updateProps:(Props::Shared const &)props oldProps:(Props::Shared const &)oldProps {
  const auto &oldViewProps = *std::static_pointer_cast<ReactNativeRichTextEditorViewProps const>(_props);
  const auto &newViewProps = *std::static_pointer_cast<ReactNativeRichTextEditorViewProps const>(props);
  BOOL heightUpdateNeeded = false;
  
  // initial config
  // TODO: handle reacting to config props when styles are relatively working
  if(_config == nullptr) {
    EditorConfig *config = [[EditorConfig alloc] init];
  
    if(newViewProps.color) {
      int32_t colorInt = (*(newViewProps.color)).getColor();
      NSNumber* nsColor = [[NSNumber alloc] initWithInt:colorInt];
      UIColor *color = [RCTConvert UIColor: nsColor];
      [config setPrimaryColor:color];
    }
    
    if(newViewProps.fontSize) {
      NSNumber* fontSize = [[NSNumber alloc] initWithFloat: newViewProps.fontSize];
      [config setPrimaryFontSize: fontSize];
    }
    
    if(!newViewProps.fontWeight.empty()) {
      [config setPrimaryFontWeight: [NSString fromCppString:newViewProps.fontWeight]];
    }
    
    if(!newViewProps.fontFamily.empty()) {
      [config setPrimaryFontFamily: [NSString fromCppString:newViewProps.fontFamily]];
    }
    
    // set the config
    _config = config;
    // fill the typing attributes
    _defaultTypingAttributes = [[NSMutableDictionary<NSAttributedStringKey, id> alloc] init];
    _defaultTypingAttributes[NSForegroundColorAttributeName] = [config primaryColor];
    _defaultTypingAttributes[NSFontAttributeName] = [config primaryFont];
    _textView.typingAttributes = _defaultTypingAttributes;
  }
  
  // default value
  if(newViewProps.defaultValue != oldViewProps.defaultValue) {
    _textView.text = [NSString fromCppString:newViewProps.defaultValue];
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
  NSMutableAttributedString *currentStr = [[NSMutableAttributedString alloc] initWithAttributedString:_textView.textStorage];
  
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

// MARK: - Native commands

- (void)handleCommand:(const NSString *)commandName args:(const NSArray *)args {
  if([commandName isEqualToString:@"focus"]) {
    [self focus];
  } else if([commandName isEqualToString:@"blur"]) {
    [self blur];
  }
}

- (void)blur {
  [_textView reactBlur];
}

- (void)focus {
  [_textView reactFocus];
}

// MARK: - UITextView delegate methods

-(bool)textView:(UITextView *)textView shouldChangeTextInRange:(NSRange)range replacementText:(NSString *)text {
  NSMutableString *newText = [[NSMutableString alloc] initWithString:textView.textStorage.string];
  [newText replaceCharactersInRange:range withString:text];
  
  static_cast<const ReactNativeRichTextEditorViewEventEmitter &>(*_eventEmitter)
    .onChangeText({ .value = [newText toCppString]});
  
  return true;
}

- (void)textViewDidChange:(UITextView *)textView {
  [self tryUpdatingHeight];
}

@end
