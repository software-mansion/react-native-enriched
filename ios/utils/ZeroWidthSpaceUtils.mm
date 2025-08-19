#import "ZeroWidthSpaceUtils.h"
#import "ReactNativeRichTextEditorView.h"
#import "StyleHeaders.h"
#import "TextInsertionUtils.h"

@implementation ZeroWidthSpaceUtils
+ (void)handleZeroWidthSpacesInEditor:(id)editor {
  ReactNativeRichTextEditorView *typedEditor = (ReactNativeRichTextEditorView *)editor;
  if(typedEditor == nullptr) { return; }
  
  [self removeSpacesIfNeededInEditor:typedEditor];
  [self addSpacesIfNeededInEditor:typedEditor];
}

+ (void)removeSpacesIfNeededInEditor:(ReactNativeRichTextEditorView *)editor {
  for(int i = 0; i < editor->textView.textStorage.string.length; i++) {
    unichar character = [editor->textView.textStorage.string characterAtIndex:i];
    if(character == 0x200B) {
      NSRange characterRange = NSMakeRange(i, 1);
      
      NSRange paragraphRange = [editor->textView.textStorage.string paragraphRangeForRange:characterRange];
      // having paragraph longer than 1 character means someone most likely added something and we probably can remove the space
      BOOL removeSpace = paragraphRange.length > 1;
      // exception; 2 characters paragraph with zero width space + newline
      // here, we still need zero width space to keep the empty list items
      if(paragraphRange.length == 2 &&
         paragraphRange.location == i &&
         [[NSCharacterSet newlineCharacterSet] characterIsMember:[editor->textView.textStorage.string characterAtIndex:i+1]]
      ) {
        removeSpace = NO;
      }
      
      if(removeSpace) {
        [TextInsertionUtils replaceText:@"" at:characterRange additionalAttributes:nullptr editor:editor];
        return;
      }
      
      UnorderedListStyle *ulStyle = editor->stylesDict[@([UnorderedListStyle getStyleType])];
      OrderedListStyle *olStyle = editor->stylesDict[@([OrderedListStyle getStyleType])];
      BlockQuoteStyle *bqStyle = editor->stylesDict[@([BlockQuoteStyle getStyleType])];
      
      // zero width spaces with no lists/blockquote styles on them get removed
      if(![ulStyle detectStyle:characterRange] && ![olStyle detectStyle:characterRange] && ![bqStyle detectStyle:characterRange]) {
        [TextInsertionUtils replaceText:@"" at:characterRange additionalAttributes:nullptr editor:editor];
      }
    }
  }
}

+ (void)addSpacesIfNeededInEditor:(ReactNativeRichTextEditorView *)editor {
  UnorderedListStyle *ulStyle = editor->stylesDict[@([UnorderedListStyle getStyleType])];
  OrderedListStyle *olStyle = editor->stylesDict[@([OrderedListStyle getStyleType])];
  BlockQuoteStyle *bqStyle = editor->stylesDict[@([BlockQuoteStyle getStyleType])];
  NSMutableArray *indexesToBeInserted = [[NSMutableArray alloc] init];
  
  for(int i = 0; i < editor->textView.textStorage.string.length; i++) {
    unichar character = [editor->textView.textStorage.string characterAtIndex:i];
    
    if([[NSCharacterSet newlineCharacterSet] characterIsMember:character]) {
      NSRange characterRange = NSMakeRange(i, 1);
      NSRange paragraphRange = [editor->textView.textStorage.string paragraphRangeForRange:characterRange];
      
      if(paragraphRange.length == 1) {
        if([ulStyle detectStyle:characterRange] || [olStyle detectStyle:characterRange] || [bqStyle detectStyle:characterRange]) {
          // we have an empty list or quote item with no space: add it!
          [indexesToBeInserted addObject:@(paragraphRange.location)];
        }
      }
    }
  }
  
  // do the replacing
  NSInteger offset = 0;
  for(NSNumber *index in indexesToBeInserted) {
    NSRange replaceRange = NSMakeRange([index integerValue] + offset, 1);
    [TextInsertionUtils replaceText:@"\u200B\n" at:replaceRange additionalAttributes:nullptr editor:editor];
    offset += 1;
  }
  
  // additional check for last index of the input
  NSRange lastRange = NSMakeRange(editor->textView.textStorage.string.length, 0);
  NSRange lastParagraphRange = [editor->textView.textStorage.string paragraphRangeForRange:lastRange];
  if(lastParagraphRange.length == 0 && ([ulStyle detectStyle:lastRange] || [olStyle detectStyle:lastRange] || [bqStyle detectStyle:lastRange])) {
    [TextInsertionUtils insertText:@"\u200B" at:lastRange.location additionalAttributes:nullptr editor:editor];
  }
}

+ (BOOL)handleBackspaceInRange:(NSRange)range replacementText:(NSString *)text editor:(id)editor {
  if(range.length != 1 || ![text isEqualToString:@""]) { return NO; }
  ReactNativeRichTextEditorView *typedEditor = (ReactNativeRichTextEditorView *)editor;
  if(typedEditor == nullptr) { return NO; }
  
  unichar character = [typedEditor->textView.textStorage.string characterAtIndex:range.location];
  // zero-width space got backspaced
  if(character == 0x200B) {
    // in such case: remove the whole line without the endline if there is one
    
    NSRange paragraphRange = [typedEditor->textView.textStorage.string paragraphRangeForRange:range];
    NSRange removalRange = paragraphRange;
    // if whole paragraph gets removed then 0 length for style removal
    NSRange styleRemovalRange = NSMakeRange(paragraphRange.location, 0);
    
    if([[NSCharacterSet newlineCharacterSet] characterIsMember:[typedEditor->textView.textStorage.string characterAtIndex:NSMaxRange(paragraphRange) - 1]]) {
      removalRange = NSMakeRange(paragraphRange.location, paragraphRange.length - 1);
      // if endline is left then 1 length for style removal
      styleRemovalRange = NSMakeRange(paragraphRange.location, 1);
    }
    
    [TextInsertionUtils replaceText:@"" at:removalRange additionalAttributes:nullptr editor:typedEditor];
    
    // and then remove associated styling
    
    UnorderedListStyle *ulStyle = typedEditor->stylesDict[@([UnorderedListStyle getStyleType])];
    OrderedListStyle *olStyle = typedEditor->stylesDict[@([OrderedListStyle getStyleType])];
    BlockQuoteStyle *bqStyle = typedEditor->stylesDict[@([BlockQuoteStyle getStyleType])];
    
    if([ulStyle detectStyle:styleRemovalRange]) {
      [ulStyle removeAttributes:styleRemovalRange];
    } else if([olStyle detectStyle:styleRemovalRange]) {
      [olStyle removeAttributes:styleRemovalRange];
    } else if([bqStyle detectStyle:styleRemovalRange]) {
      [bqStyle removeAttributes:styleRemovalRange];
    }
    
    return YES;
  }
  return NO;
}
@end

