#import <Foundation/Foundation.h>

@class StylePair;

@interface HtmlTagInterpreter : NSObject

- (NSMutableArray *)convertTags:(NSArray *)initialTags
                      plainText:(NSString *)plainText;

@end
