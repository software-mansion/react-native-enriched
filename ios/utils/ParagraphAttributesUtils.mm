#import "ParagraphAttributesUtils.h"
#import "EnrichedTextInputView.h"
#import "StyleHeaders.h"
#import "ParagraphsUtils.h"
#import "TextInsertionUtils.h"

@implementation ParagraphAttributesUtils

// if the user backspaces the last character in a line, the iOS applies typing attributes from the previous line
// in the case of some paragraph styles it works especially bad when a list point just appears
// hence the solution - reset typing attributes
+ (BOOL)handleBackspaceInRange:(NSRange)range replacementText:(NSString *)text input:(id)input {
  EnrichedTextInputView *typedInput = (EnrichedTextInputView *)input;
  UnorderedListStyle *ulStyle = typedInput->stylesDict[@([UnorderedListStyle getStyleType])];
  OrderedListStyle *olStyle = typedInput->stylesDict[@([OrderedListStyle getStyleType])];
  BlockQuoteStyle *bqStyle = typedInput->stylesDict[@([BlockQuoteStyle getStyleType])];
  
  if(typedInput == nullptr) {
    return NO;
  }
  
  // we make sure it was a backspace (text with 0 length) and it deleted something (range longer than 0)
  if(text.length > 0 || range.length == 0) {
    return NO;
  }
  
  // find a non-newline range of the paragraph
  NSRange paragraphRange = [typedInput->textView.textStorage.string paragraphRangeForRange:range];
  
  // for lists and quotes we don't want that behavior; we want zero width spaces to appear there
  if([ulStyle detectStyle:paragraphRange] || [olStyle detectStyle:paragraphRange] || [bqStyle detectStyle:paragraphRange]) {
    return NO;
  }
  
  NSArray *paragraphs = [ParagraphsUtils getNonNewlineRangesIn:typedInput->textView range:paragraphRange];
  if(paragraphs.count == 0) {
    return NO;
  }
  
  NSRange nonNewlineRange = [(NSValue *)paragraphs.firstObject rangeValue];
  
  // if the backspace removes the whole content of a paragraph, we remove the typing attributes
  if(NSEqualRanges(nonNewlineRange, range)) {
    // do the replacement manually
    [TextInsertionUtils replaceText:text at:range additionalAttributes:nullptr input:typedInput withSelection:YES];
    // reset typing attribtues
    typedInput->textView.typingAttributes = typedInput->defaultTypingAttributes;
    return YES;
  }

  return NO;
}

@end
