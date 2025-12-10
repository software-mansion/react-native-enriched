#import "TextInsertionUtils.h"
#import "EnrichedTextInputView.h"
#import "UIView+React.h"

@implementation TextInsertionUtils
+ (void)insertText:(NSString *)text
                      at:(NSInteger)index
    additionalAttributes:
        (NSDictionary<NSAttributedStringKey, id> *)additionalAttrs
                   input:(id)input
           withSelection:(BOOL)withSelection {
  EnrichedTextInputView *typedInput = (EnrichedTextInputView *)input;
  if (typedInput == nullptr) {
    return;
  }

  UITextView *textView = typedInput->textView;

  NSMutableDictionary<NSAttributedStringKey, id> *copiedAttrs =
      [textView.typingAttributes mutableCopy];
  if (additionalAttrs != nullptr) {
    [copiedAttrs addEntriesFromDictionary:additionalAttrs];
  }

  NSAttributedString *newAttrStr =
      [[NSAttributedString alloc] initWithString:text attributes:copiedAttrs];
  [textView.textStorage insertAttributedString:newAttrStr atIndex:index];

  if (withSelection) {
    if (![textView isFirstResponder]) {
      [textView reactFocus];
    }
    textView.selectedRange = NSMakeRange(index + text.length, 0);
  }
  typedInput->recentlyChangedRange = NSMakeRange(index, text.length);
}

+ (void)replaceText:(NSString *)text
                      at:(NSRange)range
    additionalAttributes:
        (NSDictionary<NSAttributedStringKey, id> *)additionalAttrs
                   input:(id)input
           withSelection:(BOOL)withSelection {
  EnrichedTextInputView *typedInput = (EnrichedTextInputView *)input;
  if (typedInput == nullptr) {
    return;
  }

  UITextView *textView = typedInput->textView;

  [textView.textStorage replaceCharactersInRange:range withString:text];
  if (additionalAttrs != nullptr) {
    [textView.textStorage
        addAttributes:additionalAttrs
                range:NSMakeRange(range.location, [text length])];
  }

  if (withSelection) {
    if (![textView isFirstResponder]) {
      [textView reactFocus];
    }
    textView.selectedRange = NSMakeRange(range.location + text.length, 0);
  }
  typedInput->recentlyChangedRange = NSMakeRange(range.location, text.length);
}

+ (void)insertTextInAttributedString:(NSString*)text
                                  at:(NSInteger)index
               additionalAttributes:(NSDictionary<NSAttributedStringKey,id>*)additionalAttrs
                   attributedString:(NSMutableAttributedString *)attributedString
{
    NSDictionary *baseAttributes = @{};
    if (attributedString.length > 0 && index < attributedString.length) {
        baseAttributes = [attributedString attributesAtIndex:index effectiveRange:nil];
    }

    NSMutableDictionary *attrs = [baseAttributes mutableCopy];
    if (additionalAttrs) {
        [attrs addEntriesFromDictionary:additionalAttrs];
    }

    NSAttributedString *newAttrString =
        [[NSAttributedString alloc] initWithString:text attributes:attrs];

    // 4. Insert into the parent attributed string
    [attributedString insertAttributedString:newAttrString atIndex:index];
}

@end
