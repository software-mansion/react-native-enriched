#import "TextInsertionUtils.h"
#import "UIView+React.h"
#import "ReactNativeRichTextEditorView.h"

@implementation TextInsertionUtils
+ (void)insertText:(NSString*)text at:(NSInteger)index additionalAttributes:(NSDictionary<NSAttributedStringKey, id>*)additionalAttrs editor:(id)editor {
  ReactNativeRichTextEditorView *typedEditor = (ReactNativeRichTextEditorView *)editor;
  if(typedEditor == nullptr) { return; }
  
  UITextView *textView = typedEditor->textView;

  NSMutableDictionary<NSAttributedStringKey, id> *copiedAttrs = [textView.typingAttributes mutableCopy];
  if(additionalAttrs != nullptr) {
    [copiedAttrs addEntriesFromDictionary: additionalAttrs];
  }
  
  NSAttributedString *newAttrStr = [[NSAttributedString alloc] initWithString:text attributes:copiedAttrs];
  [textView.textStorage insertAttributedString:newAttrStr atIndex:index];
  
  [textView reactFocus];
  textView.selectedRange = NSMakeRange(index + text.length, 0);
  
  typedEditor->recentlyChangedRange = NSMakeRange(index, text.length);
}

+ (void)replaceText:(NSString*)text at:(NSRange)range additionalAttributes:(NSDictionary<NSAttributedStringKey, id>*)additionalAttrs editor:(id)editor {
  ReactNativeRichTextEditorView *typedEditor = (ReactNativeRichTextEditorView *)editor;
  if(typedEditor == nullptr) { return; }
  
  UITextView *textView = typedEditor->textView;

  [textView.textStorage replaceCharactersInRange:range withString:text];
  if(additionalAttrs != nullptr) {
    [textView.textStorage addAttributes:additionalAttrs range:NSMakeRange(range.location, [text length])];
  }
  
  [textView reactFocus];
  textView.selectedRange = NSMakeRange(range.location + text.length, 0);
  
  typedEditor->recentlyChangedRange = NSMakeRange(range.location, text.length);
}
@end
