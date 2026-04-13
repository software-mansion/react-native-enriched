#import "EnrichedViewHost.h"
#import <UIKit/UIKit.h>

@interface TextInsertionUtils : NSObject
+ (void)insertText:(NSString *)text
                      at:(NSInteger)index
    additionalAttributes:
        (NSDictionary<NSAttributedStringKey, id> *)additionalAttrs
                   input:(id<EnrichedViewHost>)host
           withSelection:(BOOL)withSelection;
+ (void)replaceText:(NSString *)text
                      at:(NSRange)range
    additionalAttributes:
        (NSDictionary<NSAttributedStringKey, id> *)additionalAttrs
                   input:(id<EnrichedViewHost>)host
           withSelection:(BOOL)withSelection;
@end
