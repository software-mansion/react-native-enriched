#import "TextInsertionUtils.h"
#import "UIView+React.h"


@implementation TextInsertionUtils
+ (void)insertText:(NSString*)text inView:(UITextView*)textView at:(NSInteger)index additionalAttributes:(NSDictionary<NSAttributedStringKey, id>*)additionalAttrs editor:(ReactNativeRichTextEditorView *)editor {
  NSMutableDictionary<NSAttributedStringKey, id> *copiedAttrs = [textView.typingAttributes mutableCopy];
  if(additionalAttrs != nullptr) {
    [copiedAttrs addEntriesFromDictionary: additionalAttrs];
  }
  
  NSAttributedString *newAttrStr = [[NSAttributedString alloc] initWithString:text attributes:copiedAttrs];
  [textView.textStorage insertAttributedString:newAttrStr atIndex:index];
  
  [textView reactFocus];
  textView.selectedRange = NSMakeRange(index + text.length, 0);
  
  if(editor != nullptr) {
    editor->recentlyChangedRange = NSMakeRange(index, text.length);
  }
}

+ (void)replaceText:(NSString*)text inView:(UITextView*)textView at:(NSRange)range additionalAttributes:(NSDictionary<NSAttributedStringKey, id>*)additionalAttrs editor:(ReactNativeRichTextEditorView *)editor {
  [textView.textStorage replaceCharactersInRange:range withString:text];
  if(additionalAttrs != nullptr) {
    [textView.textStorage addAttributes:additionalAttrs range:NSMakeRange(range.location, [text length])];
  }
  
  [textView reactFocus];
  textView.selectedRange = NSMakeRange(range.location + text.length, 0);
  
  if(editor != nullptr) {
    editor->recentlyChangedRange = NSMakeRange(range.location, text.length);
  }
}
@end
