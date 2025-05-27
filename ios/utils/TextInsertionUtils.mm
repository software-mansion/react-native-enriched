#import "TextInsertionUtils.h"
#import "UIView+React.h"

@implementation TextInsertionUtils
+ (void)insertText:(NSString*)text inView:(UITextView*)textView at:(NSInteger)index additionalAttributes:(NSDictionary<NSAttributedStringKey, id>*)additionalAttrs {
  NSMutableDictionary<NSAttributedStringKey, id> *copiedAttrs = [[NSMutableDictionary<NSAttributedStringKey, id> alloc ] init];
  if(index == textView.textStorage.length) {
    if(index > 0) {
      // if we are at the end of the text, we want to use previous style, but only if the index won't be -1 then
      copiedAttrs = [textView.textStorage attributesAtIndex:index - 1 effectiveRange:nullptr].mutableCopy;
    }
  } else {
      copiedAttrs = [textView.textStorage attributesAtIndex:index effectiveRange:nullptr].mutableCopy;
  }
  if([copiedAttrs count] == 0) {
    copiedAttrs = textView.typingAttributes.mutableCopy;
  }
  if(additionalAttrs != nullptr) {
    [copiedAttrs addEntriesFromDictionary: additionalAttrs];
  }
  
  NSAttributedString *newAttrStr = [[NSAttributedString alloc] initWithString:text attributes:copiedAttrs];
  [textView.textStorage insertAttributedString:newAttrStr atIndex:index];
  
  [textView reactFocus];
  textView.selectedRange = NSMakeRange(index + text.length, 0);
}

+ (void)replaceText:(NSString*)text inView:(UITextView*)textView at:(NSRange)range additionalAttributes:(NSDictionary<NSAttributedStringKey, id>*)additionalAttrs {
  [textView.textStorage replaceCharactersInRange:range withString:text];
  if(additionalAttrs != nullptr) {
    [textView.textStorage addAttributes:additionalAttrs range:NSMakeRange(range.location, [text length])];
  }
  
  [textView reactFocus];
  textView.selectedRange = NSMakeRange(range.location + text.length, 0);
}
@end
