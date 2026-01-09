#import "InputTextView.h"
#import "EnrichedTextInputView.h"
#import "StringExtension.h"
#import "TextInsertionUtils.h"
#import <UniformTypeIdentifiers/UniformTypeIdentifiers.h>

// for some reason UIKit may produce different size with the same text
// the difference is always ~0.5
static const CGFloat Epsilon = 0.5;

static inline BOOL CGSizeAlmostEqual(CGSize firstSize, CGSize secondSize,
                                     CGFloat epsilon) {
  return fabs(firstSize.width - secondSize.width) < epsilon &&
         fabs(firstSize.height - secondSize.height) < epsilon;
}

@implementation InputTextView {
  UILabel *_placeholderView;
  CGSize _lastCommittedSize;
};

- (instancetype)initWithFrame:(CGRect)frame {
  if ((self = [super initWithFrame:frame])) {
    _placeholderView = [[UILabel alloc] initWithFrame:self.bounds];
    _placeholderView.isAccessibilityElement = NO;
    _placeholderView.numberOfLines = 0;
    [self addSubview:_placeholderView];

    self.textContainer.lineFragmentPadding = 0;
    self.scrollEnabled = YES;
    self.scrollsToTop = NO;
    _lastCommittedSize = CGSizeZero;
  }
  return self;
}

- (void)copy:(id)sender {
  EnrichedTextInputView *typedInput = (EnrichedTextInputView *)_input;
  if (typedInput == nullptr) {
    return;
  }

  // remove zero width spaces before copying the text
  NSString *plainText = [typedInput->textView.textStorage.string
      substringWithRange:typedInput->textView.selectedRange];
  NSString *fixedPlainText =
      [plainText stringByReplacingOccurrencesOfString:@"\u200B" withString:@""];

  NSString *parsedHtml = [typedInput->parser
      parseToHtmlFromRange:typedInput->textView.selectedRange];

  NSMutableAttributedString *attrStr = [[typedInput->textView.textStorage
      attributedSubstringFromRange:typedInput->textView.selectedRange]
      mutableCopy];
  NSRange fullAttrStrRange = NSMakeRange(0, attrStr.length);
  [attrStr.mutableString replaceOccurrencesOfString:@"\u200B"
                                         withString:@""
                                            options:0
                                              range:fullAttrStrRange];

  NSData *rtfData =
      [attrStr dataFromRange:NSMakeRange(0, attrStr.length)
          documentAttributes:@{
            NSDocumentTypeDocumentAttribute : NSRTFTextDocumentType
          }
                       error:nullptr];

  UIPasteboard *pasteboard = [UIPasteboard generalPasteboard];
  [pasteboard setItems:@[ @{
                UTTypeUTF8PlainText.identifier : fixedPlainText,
                UTTypeHTML.identifier : parsedHtml,
                UTTypeRTF.identifier : rtfData
              } ]];
}

- (void)paste:(id)sender {
  EnrichedTextInputView *typedInput = (EnrichedTextInputView *)_input;
  if (typedInput == nullptr) {
    return;
  }

  UIPasteboard *pasteboard = [UIPasteboard generalPasteboard];
  NSArray<NSString *> *pasteboardTypes = pasteboard.pasteboardTypes;
  NSRange currentRange = typedInput->textView.selectedRange;

  if ([pasteboardTypes containsObject:UTTypeHTML.identifier]) {
    // we try processing the html contents

    NSString *htmlString;
    id htmlValue = [pasteboard valueForPasteboardType:UTTypeHTML.identifier];

    if ([htmlValue isKindOfClass:[NSData class]]) {
      htmlString = [[NSString alloc] initWithData:htmlValue
                                         encoding:NSUTF8StringEncoding];
    } else if ([htmlValue isKindOfClass:[NSString class]]) {
      htmlString = htmlValue;
    }

    // validate the html
    NSString *initiallyProcessedHtml =
        [typedInput->parser initiallyProcessHtml:htmlString];

    if (initiallyProcessedHtml != nullptr) {
      // valid html, let's apply it
      currentRange.length > 0
          ? [typedInput->parser replaceFromHtml:initiallyProcessedHtml
                                          range:currentRange]
          : [typedInput->parser insertFromHtml:initiallyProcessedHtml
                                      location:currentRange.location];
    } else {
      // fall back to plain text, otherwise do nothing
      [self tryHandlingPlainTextItemsIn:pasteboard
                                  range:currentRange
                                  input:typedInput];
    }
  } else {
    [self tryHandlingPlainTextItemsIn:pasteboard
                                range:currentRange
                                input:typedInput];
  }

  [typedInput anyTextMayHaveBeenModified];
}

- (void)tryHandlingPlainTextItemsIn:(UIPasteboard *)pasteboard
                              range:(NSRange)range
                              input:(EnrichedTextInputView *)input {
  NSArray *existingTypes = pasteboard.pasteboardTypes;
  NSArray *handledTypes = @[
    UTTypeUTF8PlainText.identifier, UTTypePlainText.identifier,
    UTTypeURL.identifier
  ];
  NSString *plainText;

  for (NSString *type in handledTypes) {
    if (![existingTypes containsObject:type]) {
      continue;
    }

    id value = [pasteboard valueForPasteboardType:type];

    if ([value isKindOfClass:[NSData class]]) {
      plainText = [[NSString alloc] initWithData:value
                                        encoding:NSUTF8StringEncoding];
    } else if ([value isKindOfClass:[NSString class]]) {
      plainText = (NSString *)value;
    } else if ([value isKindOfClass:[NSURL class]]) {
      plainText = [(NSURL *)value absoluteString];
    }
  }

  if (!plainText) {
    return;
  }

  range.length > 0 ? [TextInsertionUtils replaceText:plainText
                                                  at:range
                                additionalAttributes:nullptr
                                               input:input
                                       withSelection:YES]
                   : [TextInsertionUtils insertText:plainText
                                                 at:range.location
                               additionalAttributes:nullptr
                                              input:input
                                      withSelection:YES];
}

- (void)cut:(id)sender {
  EnrichedTextInputView *typedInput = (EnrichedTextInputView *)_input;
  if (typedInput == nullptr) {
    return;
  }

  [self copy:sender];
  [TextInsertionUtils replaceText:@""
                               at:typedInput->textView.selectedRange
             additionalAttributes:nullptr
                            input:typedInput
                    withSelection:YES];

  [typedInput anyTextMayHaveBeenModified];
}

- (void)updatePlaceholderVisibility {
  BOOL shouldShow =
      self.placeholderText.length > 0 && self.textStorage.length == 0;

  _placeholderView.hidden = !shouldShow;
}

- (void)setText:(NSString *)text {
  [super setText:text];
  [self updatePlaceholderVisibility];
}

- (void)setAttributedText:(NSAttributedString *)attributedText {
  [super setAttributedText:attributedText];
  [self updatePlaceholderVisibility];
}

- (void)setPlaceholderText:(NSString *)newPlaceholderText {
  EnrichedTextInputView *typedInput = (EnrichedTextInputView *)_input;
  if (typedInput == nullptr) {
    return;
  }
  _placeholderText = newPlaceholderText;
  BOOL hasPlaceholder = newPlaceholderText && newPlaceholderText.length > 0;
  NSString *placeholderText = hasPlaceholder ? newPlaceholderText : @"";
  NSMutableDictionary *attributes =
      [typedInput->defaultTypingAttributes mutableCopy];
  attributes[NSForegroundColorAttributeName] = _placeholderColor;
  _placeholderView.attributedText =
      [[NSAttributedString alloc] initWithString:placeholderText
                                      attributes:attributes];
  [self setNeedsLayout];
}

- (void)layoutSubviews {
  [super layoutSubviews];

  CGRect textFrame =
      UIEdgeInsetsInsetRect(self.bounds, self.textContainerInset);

  CGFloat placeholderHeight =
      [_placeholderView sizeThatFits:textFrame.size].height;

  textFrame.size.height = MIN(placeholderHeight, textFrame.size.height);

  _placeholderView.frame = textFrame;

  CGRect usedRect =
      [self.layoutManager usedRectForTextContainer:self.textContainer];

  CGSize newSize = usedRect.size;

  if (CGSizeAlmostEqual(newSize, _lastCommittedSize, 0.5)) {
    return;
  }

  _lastCommittedSize = newSize;

  [_input commitSize:newSize];
}

@end
