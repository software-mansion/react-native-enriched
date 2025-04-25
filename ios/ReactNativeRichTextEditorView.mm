#import "ReactNativeRichTextEditorView.h"

#import <ReactNativeRichTextEditor/ComponentDescriptors.h>
#import <ReactNativeRichTextEditor/EventEmitters.h>
#import <ReactNativeRichTextEditor/Props.h>
#import <ReactNativeRichTextEditor/RCTComponentViewHelpers.h>

#import "UIView+React.h"
#import "StringUtils.h"
#import "RCTFabricComponentsPlugins.h"

using namespace facebook::react;

@interface ReactNativeRichTextEditorView () <RCTReactNativeRichTextEditorViewViewProtocol, UITextViewDelegate>

@end

@implementation ReactNativeRichTextEditorView {
  UITextView *textView;
}

// MARK: - ComponentDescriptorProvider

+ (ComponentDescriptorProvider)componentDescriptorProvider {
  return concreteComponentDescriptorProvider<ReactNativeRichTextEditorViewComponentDescriptor>();
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

- (void)setDefaults {}

- (void)setupTextView {
  textView = [[UITextView alloc] init];
  textView.delegate = self;
}

// MARK: - Props

- (void)updateProps:(Props::Shared const &)props oldProps:(Props::Shared const &)oldProps {
  const auto &oldViewProps = *std::static_pointer_cast<ReactNativeRichTextEditorViewProps const>(_props);
  const auto &newViewProps = *std::static_pointer_cast<ReactNativeRichTextEditorViewProps const>(props);
  
  if(newViewProps.defaultValue != oldViewProps.defaultValue) {
    textView.text = [NSString fromCppString:newViewProps.defaultValue];
  }
  
  [super updateProps:props oldProps:oldProps];
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
  [textView reactBlur];
}

- (void)focus {
  [textView reactFocus];
}

// MARK: - UITextView delegate methods

-(bool)textView:(UITextView *)textView shouldChangeTextInRange:(NSRange)range replacementText:(NSString *)text {
  NSMutableString *newText = [[NSMutableString alloc] initWithString:textView.textStorage.string];
  [newText replaceCharactersInRange:range withString:text];
  
  static_cast<const ReactNativeRichTextEditorViewEventEmitter &>(*_eventEmitter)
    .onChangeText({ .value = [newText toCppString]});
  
  return true;
}

@end

Class<RCTComponentViewProtocol> ReactNativeRichTextEditorViewCls(void) {
  return ReactNativeRichTextEditorView.class;
}
