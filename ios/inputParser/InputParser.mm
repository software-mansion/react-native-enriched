#import "InputParser.h"
#import "EnrichedTextInputView.h"

#import "AttributedStringBuilder.h"
#import "HtmlBuilder.h"
#import "HtmlTagInterpreter.h"
#import "HtmlTokenizer.h"
#import "StyleSanitizer.h"

#import "StyleHeaders.h"

@implementation InputParser {
  EnrichedTextInputView *_input;
  HtmlTokenizer *_tokenizer;
  HtmlTagInterpreter *_interpreter;
  StyleSanitizer *_sanitizer;
  AttributedStringBuilder *_builder;
  HtmlBuilder *_htmlBuilder;
}

- (instancetype)initWithInput:(id)input {
  self = [super init];
  _input = (EnrichedTextInputView *)input;

  _tokenizer = [HtmlTokenizer new];
  _interpreter = [HtmlTagInterpreter new];
  _sanitizer = [StyleSanitizer new];

  _builder = [AttributedStringBuilder new];
  _builder.stylesDict = _input->stylesDict;

  _htmlBuilder = [HtmlBuilder new];
  _htmlBuilder.stylesDict = _input->stylesDict;
  _htmlBuilder.input = _input;

  return self;
}

- (NSArray *)getTextAndStylesFromHtml:(NSString *)html {
  if (!html)
    return @[ @"", @[] ];
  HtmlTokenizationResult *tokens = [_tokenizer tokenize:html];

  NSMutableArray *processed = [_interpreter convertTags:tokens.initialTags
                                              plainText:tokens.plainText];

  [_sanitizer sanitizeStyles:processed
                    blocking:_input.blockingStyles
                 conflicting:_input.conflictingStyles];

  return @[ tokens.plainText, processed ];
}

- (void)replaceWholeFromHtml:(NSString *)html
    notifyAnyTextMayHaveBeenModified:(BOOL)notifyAnyTextMayHaveBeenModified {
  NSArray *parsed = [self getTextAndStylesFromHtml:html];
  NSString *plain = parsed[0];
  NSArray *styles = parsed[1];

  NSLog(@"replace whole from html %@", html);

  NSMutableAttributedString *attributedString =
      [[NSMutableAttributedString alloc]
          initWithString:plain
              attributes:_input->defaultTypingAttributes];

  [_builder apply:styles
       toAttributedString:attributedString
      offsetFromBeginning:0];

  NSTextStorage *storage = _input->textView.textStorage;
  [storage setAttributedString:attributedString];

  _input->textView.typingAttributes = _input->defaultTypingAttributes;
  if (notifyAnyTextMayHaveBeenModified) {
    [_input anyTextMayHaveBeenModified];
  }
}

- (void)replaceFromHtml:(NSString *)html range:(NSRange)range {
  NSArray *parsed = [self getTextAndStylesFromHtml:html];
  NSString *plainText = parsed[0];
  NSArray *styles = parsed[1];

  NSMutableAttributedString *inserted = [[NSMutableAttributedString alloc]
      initWithString:plainText
          attributes:_input->defaultTypingAttributes];

  [_builder apply:styles toAttributedString:inserted offsetFromBeginning:0];

  NSTextStorage *storage = _input->textView.textStorage;

  if (range.location > storage.length)
    range.location = storage.length;
  if (NSMaxRange(range) > storage.length) {
    range.length = storage.length - range.location;
  }

  [storage beginEditing];
  [storage replaceCharactersInRange:range withAttributedString:inserted];
  [storage endEditing];

  _input->textView.selectedRange =
      NSMakeRange(range.location + inserted.length, 0);
  _input->textView.typingAttributes = _input->defaultTypingAttributes;
  [_input anyTextMayHaveBeenModified];
}

- (void)insertFromHtml:(NSString *)html location:(NSInteger)location {

  NSArray *parsed = [self getTextAndStylesFromHtml:html];
  NSString *plain = parsed[0];
  NSArray *styles = parsed[1];

  NSMutableAttributedString *inserted = [[NSMutableAttributedString alloc]
      initWithString:plain
          attributes:_input->defaultTypingAttributes];

  [_builder apply:styles toAttributedString:inserted offsetFromBeginning:0];

  [_input->textView.textStorage beginEditing];
  [_input->textView.textStorage insertAttributedString:inserted
                                               atIndex:location];
  [_input->textView.textStorage endEditing];

  _input->textView.selectedRange = NSMakeRange(location + inserted.length, 0);
}

- (NSString *)initiallyProcessHtml:(NSString *)html {
  return [_tokenizer initiallyProcessHtml:html];
}

#pragma mark - NSAttributedString → HTML

- (NSString *)parseToHtmlFromRange:(NSRange)range {
  return [_htmlBuilder htmlFromRange:range];
}

@end
