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

using namespace facebook::react;

@interface ReactNativeRichTextEditorView () <RCTReactNativeRichTextEditorViewViewProtocol, UITextViewDelegate, NSObject>

@end

@implementation ReactNativeRichTextEditorView {
  UITextView *_textView;
  ReactNativeRichTextEditorViewShadowNode::ConcreteState::Shared _state;
  int _componentViewHeightUpdateCounter;
}

// MARK: - Component utils

+ (ComponentDescriptorProvider)componentDescriptorProvider {
  return concreteComponentDescriptorProvider<ReactNativeRichTextEditorViewComponentDescriptor>();
}

Class<RCTComponentViewProtocol> ReactNativeRichTextEditorViewCls(void) {
  return ReactNativeRichTextEditorView.class;
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
  _textView.delegate = self;
}

// MARK: - Props

- (void)updateProps:(Props::Shared const &)props oldProps:(Props::Shared const &)oldProps {
  const auto &oldViewProps = *std::static_pointer_cast<ReactNativeRichTextEditorViewProps const>(_props);
  const auto &newViewProps = *std::static_pointer_cast<ReactNativeRichTextEditorViewProps const>(props);
  
  if(newViewProps.defaultValue != oldViewProps.defaultValue) {
    _textView.text = [NSString fromCppString:newViewProps.defaultValue];
  }
  
  [super updateProps:props oldProps:oldProps];
}

+ (BOOL)shouldBeRecycled {
  return NO;
}

// MARK: - Measuring and states

- (CGSize)measureSize:(CGFloat)maxWidth {
  // copy the the whole attributed string
  NSMutableAttributedString *currentStr = [[NSMutableAttributedString alloc] initWithAttributedString:_textView.textStorage];
  
  // edge case: trailing newlines aren't counted towards height calculations so add a mock "I" character
  if([currentStr length] > 0 && [[currentStr.string substringFromIndex:[currentStr length] - 1] isEqualToString:@"\n"]) {
    [currentStr appendAttributedString:[[NSAttributedString alloc] initWithString:@"I"]];
  }

  CTFramesetterRef framesetter = CTFramesetterCreateWithAttributedString((CFAttributedStringRef)currentStr);
  
  const CGSize &suggestedSize = CTFramesetterSuggestFrameSizeWithConstraints(
    framesetter,
    CFRangeMake(0, currentStr.length),
    nullptr,
    CGSizeMake(maxWidth, DBL_MAX),
    nullptr
  );
  
  return suggestedSize;
}

- (void)updateState:(State::Shared const &)state oldState:(State::Shared const &)oldState {
  _state = std::static_pointer_cast<const ReactNativeRichTextEditorViewShadowNode::ConcreteState>(state);
  
  // first render with all the needed stuff already defined (state and componentView)
  // we need to run a single height calculation for any initial text
  if(oldState == nullptr) {
    [self tryUpdatingHeight];
  }
}

- (void)tryUpdatingHeight {
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
