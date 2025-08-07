#import <UIKit/UIKit.h>
#import "ReactNativeRichTextEditorView.h"

@interface TextInsertionUtils : NSObject
+ (void)insertText:(NSString*)text inView:(UITextView*)textView at:(NSInteger)index additionalAttributes:(NSDictionary<NSAttributedStringKey, id>*)additionalAttrs editor:(ReactNativeRichTextEditorView *)editor;
+ (void)replaceText:(NSString*)text inView:(UITextView*)textView at:(NSRange)range additionalAttributes:(NSDictionary<NSAttributedStringKey, id>*)additionalAttrs editor:(ReactNativeRichTextEditorView *)editor;
@end
