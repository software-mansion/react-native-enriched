#import <UIKit/UIKit.h>

@interface TextInsertionUtils : NSObject
+ (void)insertText:(NSString*)text inView:(UITextView*)textView at:(NSInteger)index additionalAttributes:(NSDictionary<NSAttributedStringKey, id>*)additionalAttrs editor:(id)editor;
+ (void)replaceText:(NSString*)text inView:(UITextView*)textView at:(NSRange)range additionalAttributes:(NSDictionary<NSAttributedStringKey, id>*)additionalAttrs editor:(id)editor;
@end
