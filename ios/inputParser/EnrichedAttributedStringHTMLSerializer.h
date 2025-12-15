#import <Foundation/Foundation.h>

@class HTMLNode;
@class HTMLTextNode;

@interface EnrichedAttributedStringHTMLSerializer : NSObject
- (instancetype)initWithStyles:(NSDictionary<NSNumber *, id> *)stylesDict;
- (NSString *)buildHtmlFromAttributedString:(NSAttributedString *)text
                                    pretify:(BOOL)pretify;
@end
