#import "EditorTextView.h"
#import "ReactNativeRichTextEditorView.h"
#import "StringExtension.h"
#import <UniformTypeIdentifiers/UniformTypeIdentifiers.h>
#import "TextInsertionUtils.h"

@implementation EditorTextView

- (void)copy:(id)sender {
  ReactNativeRichTextEditorView *typedEditor = (ReactNativeRichTextEditorView *)_editor;
  if(typedEditor == nullptr) { return; }
  
  // remove zero width spaces before copying the text
  NSString *plainText = [typedEditor->textView.textStorage.string substringWithRange:typedEditor->textView.selectedRange];
  NSString *fixedPlainText = [plainText stringByReplacingOccurrencesOfString:@"\u200B" withString:@""];
  
  NSString *escapedHtml = [NSString stringByEscapingHtml:[typedEditor->parser parseToHtmlFromRange:typedEditor->textView.selectedRange]];
  
  NSMutableAttributedString *attrStr = [[typedEditor->textView.textStorage attributedSubstringFromRange:typedEditor->textView.selectedRange] mutableCopy];
  NSRange fullAttrStrRange = NSMakeRange(0, attrStr.length);
  [attrStr.mutableString replaceOccurrencesOfString:@"\u200B" withString:@"" options:0 range:fullAttrStrRange];
  
  NSData *rtfData = [attrStr dataFromRange:NSMakeRange(0, attrStr.length)
    documentAttributes:@{NSDocumentTypeDocumentAttribute:NSRTFTextDocumentType}
    error:nullptr
  ];
  
  UIPasteboard *pasteboard = [UIPasteboard generalPasteboard];
  [pasteboard setItems:@[@{
    UTTypeUTF8PlainText.identifier : fixedPlainText,
    UTTypeHTML.identifier : escapedHtml,
    UTTypeRTF.identifier : rtfData
  }]];
}

- (void)paste:(id)sender {
  ReactNativeRichTextEditorView *typedEditor = (ReactNativeRichTextEditorView *)_editor;
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
      [self tryHandlingPlainTextItemsIn:pasteboard range:currentRange editor:typedEditor];
    }
  } else {
    [self tryHandlingPlainTextItemsIn:pasteboard range:currentRange editor:typedEditor];
  }
  
  [typedEditor anyTextMayHaveBeenModified];
}

- (void)tryHandlingPlainTextItemsIn:(UIPasteboard *)pasteboard range:(NSRange)range editor:(ReactNativeRichTextEditorView *)editor {
  NSArray *existingTypes = pasteboard.pasteboardTypes;
  NSArray *handledTypes = @[UTTypeUTF8PlainText.identifier, UTTypePlainText.identifier];
  NSString *plainText;
  
  for(NSString *type in handledTypes) {
    if(![existingTypes containsObject:type]) {
      continue;
    }
    
    id value = [pasteboard valueForPasteboardType:type];
    
    if([value isKindOfClass:[NSData class]]) {
      plainText = [[NSString alloc]initWithData:value encoding:NSUTF8StringEncoding];
    } else if([value isKindOfClass:[NSString class]]) {
      plainText = (NSString *)value;
    }
  }
  
  if(!plainText) {
    return;
  }
  
  range.length > 0
    ? [TextInsertionUtils replaceText:plainText at:range additionalAttributes:nullptr editor:editor withSelection:YES]
    : [TextInsertionUtils insertText:plainText at:range.location additionalAttributes:nullptr editor:editor withSelection:YES];
}

- (void)cut:(id)sender {
  ReactNativeRichTextEditorView *typedEditor = (ReactNativeRichTextEditorView *)_editor;
  if(typedEditor == nullptr) { return; }
  
  [self copy:sender];
  [TextInsertionUtils replaceText:@"" at:typedEditor->textView.selectedRange additionalAttributes:nullptr editor:typedEditor  withSelection:YES];
  
  [typedEditor anyTextMayHaveBeenModified];
}

@end
