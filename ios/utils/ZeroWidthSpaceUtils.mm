#import "ZeroWidthSpaceUtils.h"
#import "EnrichedTextInputView.h"
#import "StyleHeaders.h"
#import "TextInsertionUtils.h"
#import "UIView+React.h"

@implementation ZeroWidthSpaceUtils
+ (void)handleZeroWidthSpacesInInput:(id)input {
  EnrichedTextInputView *typedInput = (EnrichedTextInputView *)input;
  if(typedInput == nullptr) { return; }
  
  [self removeSpacesIfNeededinInput:typedInput];
  [self addSpacesIfNeededinInput:typedInput];
}

+ (void)removeSpacesIfNeededinInput:(EnrichedTextInputView *)input {
  NSMutableArray *indexesToBeRemoved = [[NSMutableArray alloc] init];
  NSRange preRemoveSelection = input->textView.selectedRange;

  for(int i = 0; i < input->textView.textStorage.string.length; i++) {
    unichar character = [input->textView.textStorage.string characterAtIndex:i];
    if(character == 0x200B) {
      NSRange characterRange = NSMakeRange(i, 1);
      
      NSRange paragraphRange = [input->textView.textStorage.string paragraphRangeForRange:characterRange];
      // having paragraph longer than 1 character means someone most likely added something and we probably can remove the space
      BOOL removeSpace = paragraphRange.length > 1;
      // exception; 2 characters paragraph with zero width space + newline
      // here, we still need zero width space to keep the empty list items
      if(paragraphRange.length == 2 &&
         paragraphRange.location == i &&
         [[NSCharacterSet newlineCharacterSet] characterIsMember:[input->textView.textStorage.string characterAtIndex:i+1]]
      ) {
        removeSpace = NO;
      }
      
      if(removeSpace) {
        [indexesToBeRemoved addObject:@(characterRange.location)];
        continue;
      }
      
      UnorderedListStyle *ulStyle = input->stylesDict[@([UnorderedListStyle getStyleType])];
      OrderedListStyle *olStyle = input->stylesDict[@([OrderedListStyle getStyleType])];
      BlockQuoteStyle *bqStyle = input->stylesDict[@([BlockQuoteStyle getStyleType])];
      CodeBlockStyle *cbStyle = input->stylesDict[@([CodeBlockStyle getStyleType])];
      
      // zero width spaces with no lists/blockquote styles on them get removed
      if(![ulStyle detectStyle:characterRange] && ![olStyle detectStyle:characterRange] && ![bqStyle detectStyle:characterRange] && ![cbStyle detectStyle:characterRange]) {
        [indexesToBeRemoved addObject:@(characterRange.location)];
      }
    }
  }
  
  // do the removing
  NSInteger offset = 0;
  NSInteger postRemoveLocationOffset = 0;
  NSInteger postRemoveLengthOffset = 0;
  for(NSNumber *index in indexesToBeRemoved) {
    NSRange replaceRange = NSMakeRange([index integerValue] + offset, 1);
    [TextInsertionUtils replaceText:@"" at:replaceRange additionalAttributes:nullptr input:input withSelection:NO];
    offset -= 1;
    if([index integerValue] < preRemoveSelection.location) {
      postRemoveLocationOffset -= 1;
    }
    if([index integerValue] >= preRemoveSelection.location && [index integerValue] < NSMaxRange(preRemoveSelection)) {
      postRemoveLengthOffset -= 1;
    }
  }
  
  // fix the selection if needed
  if([input->textView isFirstResponder]) {
    input->textView.selectedRange = NSMakeRange(preRemoveSelection.location + postRemoveLocationOffset, preRemoveSelection.length + postRemoveLengthOffset);
  }
}

+ (void)addSpacesIfNeededinInput:(EnrichedTextInputView *)input {
  UnorderedListStyle *ulStyle = input->stylesDict[@([UnorderedListStyle getStyleType])];
  OrderedListStyle *olStyle = input->stylesDict[@([OrderedListStyle getStyleType])];
  BlockQuoteStyle *bqStyle = input->stylesDict[@([BlockQuoteStyle getStyleType])];
  CodeBlockStyle *cbStyle = input->stylesDict[@([CodeBlockStyle getStyleType])];
  NSMutableArray *indexesToBeInserted = [[NSMutableArray alloc] init];
  NSRange preAddSelection = input->textView.selectedRange;
  
  for(int i = 0; i < input->textView.textStorage.string.length; i++) {
    unichar character = [input->textView.textStorage.string characterAtIndex:i];
    
    if([[NSCharacterSet newlineCharacterSet] characterIsMember:character]) {
      NSRange characterRange = NSMakeRange(i, 1);
      NSRange paragraphRange = [input->textView.textStorage.string paragraphRangeForRange:characterRange];
      
      if(paragraphRange.length == 1) {
        if([ulStyle detectStyle:characterRange] || [olStyle detectStyle:characterRange] || [bqStyle detectStyle:characterRange] || [cbStyle detectStyle:characterRange]) {
          // we have an empty list or quote item with no space: add it!
          [indexesToBeInserted addObject:@(paragraphRange.location)];
        }
      }
    }
  }
  
  // do the replacing
  NSInteger offset = 0;
  NSInteger postAddLocationOffset = 0;
  NSInteger postAddLengthOffset = 0;
  for(NSNumber *index in indexesToBeInserted) {
    NSRange replaceRange = NSMakeRange([index integerValue] + offset, 1);
    [TextInsertionUtils replaceText:@"\u200B\n" at:replaceRange additionalAttributes:nullptr input:input withSelection:NO];
    offset += 1;
    if([index integerValue] < preAddSelection.location) {
      postAddLocationOffset += 1;
    }
    if([index integerValue] >= preAddSelection.location && [index integerValue] < NSMaxRange(preAddSelection)) {
      postAddLengthOffset += 1;
    }
  }
  
  // additional check for last index of the input
  NSRange lastRange = NSMakeRange(input->textView.textStorage.string.length, 0);
  NSRange lastParagraphRange = [input->textView.textStorage.string paragraphRangeForRange:lastRange];
  if(lastParagraphRange.length == 0 && ([ulStyle detectStyle:lastRange] || [olStyle detectStyle:lastRange] || [bqStyle detectStyle:lastRange] || [cbStyle detectStyle:lastRange])) {
    [TextInsertionUtils insertText:@"\u200B" at:lastRange.location additionalAttributes:nullptr input:input withSelection:NO];
  }
  
  // fix the selection if needed
  if([input->textView isFirstResponder]) {
    input->textView.selectedRange = NSMakeRange(preAddSelection.location + postAddLocationOffset, preAddSelection.length + postAddLengthOffset);
  }
}

+ (BOOL)handleBackspaceInRange:(NSRange)range replacementText:(NSString *)text input:(id)input {
  if(range.length != 1 || ![text isEqualToString:@""]) { return NO; }
  EnrichedTextInputView *typedInput = (EnrichedTextInputView *)input;
  if(typedInput == nullptr) { return NO; }
  
  unichar character = [typedInput->textView.textStorage.string characterAtIndex:range.location];
  // zero-width space got backspaced
  if(character == 0x200B) {
    // in such case: remove the whole line without the endline if there is one
    
    NSRange paragraphRange = [typedInput->textView.textStorage.string paragraphRangeForRange:range];
    NSRange removalRange = paragraphRange;
    // if whole paragraph gets removed then 0 length for style removal
    NSRange styleRemovalRange = NSMakeRange(paragraphRange.location, 0);
    
    if([[NSCharacterSet newlineCharacterSet] characterIsMember:[typedInput->textView.textStorage.string characterAtIndex:NSMaxRange(paragraphRange) - 1]]) {
      // if endline is there, don't remove it
      removalRange = NSMakeRange(paragraphRange.location, paragraphRange.length - 1);
      // if endline is left then 1 length for style removal
      styleRemovalRange = NSMakeRange(paragraphRange.location, 1);
    }
    
    // and then remove associated styling
    
    UnorderedListStyle *ulStyle = typedInput->stylesDict[@([UnorderedListStyle getStyleType])];
    OrderedListStyle *olStyle = typedInput->stylesDict[@([OrderedListStyle getStyleType])];
    BlockQuoteStyle *bqStyle = typedInput->stylesDict[@([BlockQuoteStyle getStyleType])];
    CodeBlockStyle *cbStyle = typedInput->stylesDict[@([CodeBlockStyle getStyleType])];
    
    if([cbStyle detectStyle:removalRange]) {
      // code blocks are being handled differently; we want to remove previous newline if there is a one
      if(range.location > 0) {
        removalRange = NSMakeRange(removalRange.location - 1, removalRange.length + 1);
      }
      [TextInsertionUtils replaceText:@"" at:removalRange additionalAttributes:nullptr input:typedInput withSelection:YES];
      return YES;
    }
    
    [TextInsertionUtils replaceText:@"" at:removalRange additionalAttributes:nullptr input:typedInput withSelection:YES];
    
    if ([ulStyle detectStyle:styleRemovalRange]) {
      [ulStyle removeAttributes:styleRemovalRange];
    } else if ([olStyle detectStyle:styleRemovalRange]) {
      [olStyle removeAttributes:styleRemovalRange];
    } else if ([bqStyle detectStyle:styleRemovalRange]) {
      [bqStyle removeAttributes:styleRemovalRange];
    }
    
    return YES;
  }
  return NO;
}

@end
