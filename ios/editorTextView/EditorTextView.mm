#import "EditorTextView.h"
#import "EditorManager.h"
#import "ReactNativeRichTextEditorView.h"
#import "StringExtension.h"
#import <UniformTypeIdentifiers/UniformTypeIdentifiers.h>
#import "TextInsertionUtils.h"

@implementation EditorTextView

- (void)copy:(id)sender {
  ReactNativeRichTextEditorView *typedEditor = (ReactNativeRichTextEditorView *)[EditorManager sharedManager].currentEditor;
  if(typedEditor == nullptr) { return; }
  
  NSString *plainText = [typedEditor->textView.textStorage.string substringWithRange:typedEditor->textView.selectedRange];
  NSString *escapedHtml = [NSString stringByEscapingHtml:[typedEditor->parser parseToHtmlFromRange:typedEditor->textView.selectedRange]];
  NSAttributedString *attrStr = [typedEditor->textView.textStorage attributedSubstringFromRange:typedEditor->textView.selectedRange];
  NSData *rtfData = [attrStr dataFromRange:NSMakeRange(0, attrStr.length)
    documentAttributes:@{NSDocumentTypeDocumentAttribute:NSRTFTextDocumentType}
    error:nullptr
  ];
  
  UIPasteboard *pasteboard = [UIPasteboard generalPasteboard];
  [pasteboard setItems:@[@{
    UTTypePlainText.identifier : plainText,
    UTTypeHTML.identifier : escapedHtml,
    UTTypeRTF.identifier : rtfData
  }]];
}

- (void)paste:(id)sender {
  ReactNativeRichTextEditorView *typedEditor = (ReactNativeRichTextEditorView *)[EditorManager sharedManager].currentEditor;
  if(typedEditor == nullptr) { return; }

  UIPasteboard *pasteboard = [UIPasteboard generalPasteboard];
  NSArray<NSString *> *pasteboardTypes = pasteboard.pasteboardTypes;
  NSRange currentRange = typedEditor->textView.selectedRange;
  
  if([pasteboardTypes containsObject:UTTypeHTML.identifier]) {
    // we try processing the html contents
    
    NSString *htmlString;
    id htmlValue = [pasteboard valueForPasteboardType:UTTypeHTML.identifier];
    
    if([htmlValue isKindOfClass:[NSData class]]) {
      htmlString = [[NSString alloc]initWithData:htmlValue encoding:NSUTF8StringEncoding];
    } else if([htmlValue isKindOfClass:[NSString class]]) {
      htmlString = htmlValue;
    }
    
    // unescape the html
    htmlString = [NSString stringByUnescapingHtml:htmlString];
    // validate it
    NSString *initiallyProcessedHtml = [typedEditor->parser initiallyProcessHtml:htmlString];
    
    if(initiallyProcessedHtml != nullptr) {
      // valid html, let's apply it
      currentRange.length > 0
        ? [typedEditor->parser replaceFromHtml:initiallyProcessedHtml range:currentRange]
        : [typedEditor->parser insertFromHtml:initiallyProcessedHtml location:currentRange.location];
    } else {
      // fall back to plain text, otherwise do nothing
      if([pasteboardTypes containsObject:UTTypePlainText.identifier]) {
        NSString *plainString = [pasteboard valueForPasteboardType:UTTypePlainText.identifier];
        currentRange.length > 0
          ? [TextInsertionUtils replaceText:plainString inView:typedEditor->textView at:currentRange additionalAttributes:nullptr]
          : [TextInsertionUtils insertText:plainString inView:typedEditor->textView at:currentRange.location additionalAttributes:nullptr];
      }
    }
  } else if([pasteboardTypes containsObject:UTTypePlainText.identifier]) {
    // just plain text
  
    NSString *plainString = [pasteboard valueForPasteboardType:UTTypePlainText.identifier];
    currentRange.length > 0
      ? [TextInsertionUtils replaceText:plainString inView:typedEditor->textView at:currentRange additionalAttributes:nullptr]
      : [TextInsertionUtils insertText:plainString inView:typedEditor->textView at:currentRange.location additionalAttributes:nullptr];
  }
}

- (void)cut:(id)sender {
  ReactNativeRichTextEditorView *typedEditor = (ReactNativeRichTextEditorView *)[EditorManager sharedManager].currentEditor;
  if(typedEditor == nullptr) { return; }
  
  [self copy:sender];
  [TextInsertionUtils replaceText:@"" inView:typedEditor->textView at:typedEditor->textView.selectedRange additionalAttributes:nullptr];
}

@end
