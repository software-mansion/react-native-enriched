#import "InputParser.h"
#import "EnrichedTextInputView.h"

#import "AttributedStringBuilder.h"
#import "ConvertHtmlToPlainTextAndStylesResult.h"
#import "HtmlBuilder.h"
#import "HtmlHandler.h"

#import "StyleHeaders.h"

@implementation InputParser {
  EnrichedTextInputView *_input;
  AttributedStringBuilder *_builder;
  HtmlBuilder *_htmlBuilder;
  HtmlHandler *_htmlHandler;
}

- (instancetype)initWithInput:(id)input {
  self = [super init];
  _input = (EnrichedTextInputView *)input;

  _builder = [AttributedStringBuilder new];
  _builder.stylesDict = _input->stylesDict;

  _htmlBuilder = [HtmlBuilder new];
  _htmlBuilder.stylesDict = _input->stylesDict;
  _htmlBuilder.input = _input;

  _htmlHandler = [HtmlHandler new];

  return self;
}

- (void)replaceWholeFromHtml:(NSString *)html
    notifyAnyTextMayHaveBeenModified:(BOOL)notifyAnyTextMayHaveBeenModified {
  ConvertHtmlToPlainTextAndStylesResult *plainTextAndStyles =
      [_htmlHandler getTextAndStylesFromHtml:html];

  NSMutableAttributedString *attributedString =
      [[NSMutableAttributedString alloc]
          initWithString:plainTextAndStyles.text
              attributes:_input->defaultTypingAttributes];

  [_builder apply:plainTextAndStyles.styles
       toAttributedString:attributedString
      offsetFromBeginning:0
        conflictingStyles:_input->conflictingStyles];

  NSTextStorage *storage = _input->textView.textStorage;
  [storage setAttributedString:attributedString];

  _input->textView.typingAttributes = _input->defaultTypingAttributes;
  if (notifyAnyTextMayHaveBeenModified) {
    [_input anyTextMayHaveBeenModified];
  }
}

- (void)replaceFromHtml:(NSString *)html range:(NSRange)range {
  ConvertHtmlToPlainTextAndStylesResult *plainTextAndStyles =
      [_htmlHandler getTextAndStylesFromHtml:html];

  NSMutableAttributedString *inserted = [[NSMutableAttributedString alloc]
      initWithString:plainTextAndStyles.text
          attributes:_input->defaultTypingAttributes];

  [_builder apply:plainTextAndStyles.styles
       toAttributedString:inserted
      offsetFromBeginning:0
        conflictingStyles:_input->conflictingStyles];

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

  ConvertHtmlToPlainTextAndStylesResult *plainTextAndStyles =
      [_htmlHandler getTextAndStylesFromHtml:html];

  NSMutableAttributedString *inserted = [[NSMutableAttributedString alloc]
      initWithString:plainTextAndStyles.text
          attributes:_input->defaultTypingAttributes];

  [_builder apply:plainTextAndStyles.styles
       toAttributedString:inserted
      offsetFromBeginning:0
        conflictingStyles:_input->conflictingStyles];

  [_input->textView.textStorage beginEditing];
  [_input->textView.textStorage insertAttributedString:inserted
                                               atIndex:location];
  [_input->textView.textStorage endEditing];

  _input->textView.selectedRange = NSMakeRange(location + inserted.length, 0);
}

- (NSString *)initiallyProcessHtml:(NSString *)html {
  return [_htmlHandler initiallyProcessHtml:html];
}

#pragma mark - NSAttributedString → HTML

- (NSString *)parseToHtmlFromRange:(NSRange)range {
  return [_htmlBuilder htmlFromRange:range];
}

@end
