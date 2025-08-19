#import <UIKit/UIKit.h>

@interface TextInsertionUtils : NSObject
+ (void)insertText:(NSString*)text at:(NSInteger)index additionalAttributes:(NSDictionary<NSAttributedStringKey, id>*)additionalAttrs editor:(id)editor;
+ (void)replaceText:(NSString*)text at:(NSRange)range additionalAttributes:(NSDictionary<NSAttributedStringKey, id>*)additionalAttrs editor:(id)editor;
@end
