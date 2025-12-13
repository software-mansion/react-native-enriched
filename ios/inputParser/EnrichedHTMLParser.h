#import <Foundation/Foundation.h>

@class HTMLNode;
@class HTMLTextNode;

#pragma mark - Public Builder

@interface EnrichedHTMLParser : NSObject
- (instancetype)initWithStyles:(NSDictionary<NSNumber *, id> *)stylesDict;
- (NSString *)buildHtmlFromAttributedString:(NSAttributedString *)text
                                    pretify:(BOOL)pretify;
@end
